"chef-server": {
  "api_fqdn": "${fqdn}",
   "oc_id['administrators'] = ['${chef-server-user}']
   
"oc_id['applications']" = {
    'supermarket' => {
       'redirect_uri' =>'${redirect_uri}/auth/chef_oauth2/callback'
     }
  }
}
