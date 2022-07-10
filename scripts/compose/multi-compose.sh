alias compose=docker-compose -f docker-compose.yml $(for file in include/compose/*.yml; do echo "-f $$file"; done)
