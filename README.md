after running the terraform scripts, to access the Elasticsearch and Kibana site, run

    docker run \
        -d \
        -e AWS_ACCESS_KEY_ID=[access_key] \
        -e AWS_SECRET_ACCESS_KEY=[secret_key] \
        -p 127.0.0.1:9200:9200 \
         santthosh/aws-es-kibana -b 0.0.0.0 <endpoint_address>

or use a client that knows how to do aws authentication (like Paw)
