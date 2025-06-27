#!/bin/bash
aws s3 cp <s3 bucket uri> /etc/nginx/nginx.conf
systemctl restart nginx
