docker run -d \
  --name homeassistant \
    --privileged \
      --restart=unless-stopped \
        -e TZ=MY_TIME_ZONE \
          -v C:/env/docker/smarthome:/config \
            --network=host \
              ghcr.io/home-assistant/home-assistant:stable
