require 'docker'

# To test docker api library

# To expose 1234 to host with a specified host port
# docker run -p 1234:1234 image-name
Docker::Container.create(
  'Image' => 'slapin-1',
  'ExposedPorts' => { '5000/tcp' => {} },
  'HostConfig' => {
    'PortBindings' => {
      '5000/tcp' => [{ 'HostPort' => '5000' }]
    }
  }
)