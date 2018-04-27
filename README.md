after running the terraform scripts, to access the Elasticsearch and Kibana site, run

    docker run -e AWS_PROFILE=<profile> -p 127.0.0.1:9200:9200 -v $(pwd)/.aws:/root/.aws santthosh/aws-es-kibana -b
     0.0.0.0 <endpoint_address>
