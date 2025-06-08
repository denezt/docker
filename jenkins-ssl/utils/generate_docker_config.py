#!/usr/bin/env python

import os
import argparse
import jinja2
from jinja2 import Environment, FileSystemLoader, Template

# Target Docker Config Container
GENSRC = "gensrc"

# Preliminary Steps
if not os.path.exists(GENSRC):
    os.mkdir(GENSRC)

container = { 'setting': {} }

environment = jinja2.Environment()
# Define the complete path
path = os.path.abspath(os.curdir)

# Current path to Dockerfile template
DOCKERFILE_TEMPLATE = 'DockerTemplates/Dockerfile.tmpl.001'

# Construct complete path to template
dockerfile_template = os.path.join(path, DOCKERFILE_TEMPLATE)
print(dockerfile_template)

"""
Docker Template Generator
"""
DOCKERFILE_PATH = f"{GENSRC}/Dockerfile"
# Store Dockerfile Template
dft = open(dockerfile_template, 'r')

# Create a Jinja2 template
templ_1 = Template(dft.read())
parser = argparse.ArgumentParser(description='Docker Configuration Generation')
parser.add_argument('--source-image','--image', type=str, help='Set Source Image')
parser.add_argument('--http-port','--http', default=-1, type=int, help='Set HTTP Port')
parser.add_argument('--https-port','--https', default=443, type=int, help='Set HTTPS Port')
args = parser.parse_args()
print(args)

container['setting']['source_image'] = args.source_image
container['setting']['http_port'] = args.http_port
container['setting']['https_port'] = args.https_port

# Render the template with the data
rendered_dockerfile = templ_1.render(container)
print(rendered_dockerfile)

# Write docker configuration to Dockerfile
generated_dockerfile = os.path.join(path, DOCKERFILE_PATH)
with open(generated_dockerfile, "w") as dockerfile:
    dockerfile.write(rendered_dockerfile)

"""
Docker Compose Generator
"""
DOCKERCOMPOSE_PATH = f"{GENSRC}/docker-compose.yaml"
# Current path to Dockerfile template
dockercompose_template = os.path.join(path, 'DockerTemplates/docker-compose.yaml.tmpl.001')
print(dockercompose_template)

# Store Docker Compose Template
dct = open(dockercompose_template, 'r')
templ_2 = Template(dct.read())

# Render the template with the data
rendered_dockercompose = templ_2.render(container)
print(rendered_dockercompose)

# Write docker configuration to Docker Compose file
generated_dockercompose = os.path.join(path, DOCKERCOMPOSE_PATH)
with open(generated_dockercompose, "w") as dockercompose:
    dockercompose.write(rendered_dockercompose)