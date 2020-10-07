#!/usr/bin/env python3
# -*- coding: utf-8 -*-
'''
serve models hosted on a mlflow+s3
'''
from __future__ import absolute_import, division, print_function
import sys
import os
import mlflow
import shutil
import re
from mlflow.tracking import MlflowClient
import subprocess
import tempfile
from mlflow.entities.model_registry.model_version_status import ModelVersionStatus
LOCAL_PATHR = os.environ.get('TF_MODEL_PATH', '/data')
MLFLOWDIR = os.path.join(LOCAL_PATHR, 'mf')
TFLOWDIR = os.path.join(LOCAL_PATHR, 'tf')
def create_dirs(*d):
    if not isinstance(d, (tuple, list)):
        d = [d]
    for c in d:
        if not os.path.exists(c):
            os.makedirs(c)
dockerhost = subprocess.check_output('''\
ip -4 route list match 0/0 \
    | awk '{print $3" host.docker.internal"}'
''', shell=True).decode('utf-8', 'ignore').strip()
subprocess.check_output(
    f'echo {dockerhost} host.docker.internal >> /etc/hosts',
    shell=True)
os.environ['DOCKER_HOST_IP'] = dockerhost
os.environ['S3_ENDPOINT'] = os.environ['AWS_S3_ENDPOINT_URL']
# download model
MODEL_URI_RE = re.compile('(?P<scheme>.*):/(?P<model>[^/]+)/(?P<stage>.*)$', flags=re.I)
sourcere = re.compile(
    's3://(?P<bucket>[^/]+)/(?P<runid>[^/]+)/artifacts/(?P<path>.*$)')
models = {}

for model in os.environ.get('MLFLOW_MODELS', '').split(';'):
    models[model] = {
        'uri': os.environ.get(model.upper() + '_MODELE_PATH_URI',
                              f'models:/{model}/Production')
    }

def fetch():
    client = MlflowClient()
    create_dirs(MLFLOWDIR, TFLOWDIR)
    for m in [a for a in models]:
        mdata = models[m]
        uri = mdata['uri']
        match = MODEL_URI_RE.search(uri)
        gr = match.groupdict()
        version = [
            v for v in client.search_registered_models(
                filter_string=f"name='{gr['model']}'")[0].latest_versions
            if v.current_stage == gr['stage']][0]
        vmatch = sourcere.search(version.source)
        vgr = vmatch.groupdict()
        mlflowdir = os.path.join(MLFLOWDIR, m)
        tflowdir = os.path.join(TFLOWDIR, m)
        if os.path.exists(tflowdir):
            shutil.rmtree(tflowdir)
        create_dirs(mlflowdir, tflowdir)
        client.download_artifacts(vgr['runid'], vgr['path'], mlflowdir)
        found = False
        for i in ['tfmodel', 'model']:
            mdldir = os.path.join(mlflowdir, 'model', i)
            if os.path.exists(mdldir):
                os.rename(mdldir, tflowdir + '/1')
                found = True
        if found:
            continue
        raise Exception(f'{m}: model not found')

if os.environ.get('SKIP_FETCH'):
    print('Skip fetch')
else:
    fetch()

configp = '/data/config.tf'
config = 'model_config_list {\n'
for i in os.listdir(TFLOWDIR):
    config += f'''
  config {{
    name: '{i}'
    base_path: '{TFLOWDIR}/{i}'
    model_platform: 'tensorflow'
  }}
'''
config += '\n}'
with open(configp, 'w') as fic:
	fic.write(config)
print('Using config:\n')
print(open(configp).read())
tfargs = sys.argv[1:]
EP = '/usr/bin/tf_serving_entrypoint.sh'
if not tfargs:
    tfargs = [f'--port=8500',
              f'--rest_api_port=8501',
              f"--model_config_file={configp}"]
else:
    EP = sys.argv[1]
os.execvpe(EP, tfargs, env=os.environ)
# vim:set et sts=4 ts=4 tw=0:
