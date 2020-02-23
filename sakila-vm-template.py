"""
Deployment Manager Template for creating a GCE instance 
"""
COMPUTE_URL_BASE = 'https://www.googleapis.com/compute/v1/'


def global_compute_url(project, collection, name):
    return ''.join([COMPUTE_URL_BASE, 'projects/', project,
                    '/global/', collection, '/', name])


def zonal_compute_url(project, zone, collection, name):
    return ''.join([COMPUTE_URL_BASE, 'projects/', project,
                    '/zones/', zone, '/', collection, '/', name])


def generate_config(context):

    base_name = context.env['deployment'] + '-' + context.env['name']

    items = []
    for key, value in context.properties['metadata-from-file'].items():
        items.append({
            'key': key,
            'value': context.imports[value]
        })
    metadata = {'items': items}

    resources = [{
        'type': 'compute.v1.instance',
        'name': 'sakila-vm',
        'properties': {
            'zone': context.properties['zone'],
            'machineType': zonal_compute_url(context.env['project'], context.properties['zone'],
                                             'machineTypes', 'g1-small'),
            'tags':{
                'items': ['flask-mysql-server']
            },
            'metadata': metadata,
            'disks': [{
                'deviceName': 'boot',
                'type': 'PERSISTENT',
                'autoDelete': True,
                'boot': True,
                'initializeParams': {
                    'diskName': base_name + '-disk',
                    'sourceImage': global_compute_url('debian-cloud', 'images', 'family/debian-9')
                },
            }],
            'networkInterfaces': [{
                'network': global_compute_url(context.env['project'], 'networks', 'default'),
                'accessConfigs': [{
                    'name': 'External NAT',
                    'type': 'ONE_TO_ONE_NAT'
                }]
            }]

        }
    },
        {
        'type': 'compute.v1.firewall',
        'name': 'sakila-app-firewall',
        'properties': {
            'allowed': [{
                'IPProtocol': 'TCP',
                'ports': ['80', '5000', '3306']
            }],
            'sourceRanges': ['0.0.0.0/0'],
            'targetTags': ['flask-mysql-server']
        }
    }]

    return {'resources': resources}
