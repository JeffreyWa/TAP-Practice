#!/usr/local/bin/bash

declare -A orgMap
declare -A spaceMap

PER_PAGE=20


function init_org(){
    total_pages=$(cf curl /v3/organizations?per_page=$PER_PAGE | jq .pagination.total_pages)
    echo $total_pages
    for (( i = 1; i <= $total_pages; i++ ))
    do
       org_list=$(cf curl "/v3/organizations?per_page=$PER_PAGE&page=$i" | jq '.resources[] | {name, guid}' | jq -c .)
       for org in $org_list
       do
         #echo $org
         _name=$(echo $org | jq -r .name)
         #echo $_name
         _guid=$(echo $org | jq -r .guid)
         #echo $_guid
         orgMap[$_guid]=$_name     
       done
    done
    #echo ${!orgMap[@]}
    #echo ${orgMap[@]}
}

function init_space(){
    #total_pages=$(cf curl /v3/spaces?organization_guids=$1&per_page=1 | jq .pagination.total_pages)
    total_pages=$(cf curl /v3/spaces?per_page=$PER_PAGE  | jq .pagination.total_pages)
    echo $total_pages
    for (( i = 1; i <= $total_pages; i++ ))
    do
       space_list=$(cf curl "/v3/spaces?per_page=$PER_PAGE&page=$i" | jq '.resources[] | {name, guid}' | jq -c .)
       for space in $space_list
       do
         #echo $space
         _name=$(echo $space | jq -r .name)
         #echo $_name
         _guid=$(echo $space | jq -r .guid)
         #echo $_guid
         spaceMap[$_guid]=$_name    
       done
    done
    #echo ${!spaceMap[@]}
    #echo ${spaceMap[@]}
}


function get_events(){
    start_date=$1

    total_pages=$(cf curl "/v2/events?created_ats[gt]=$start_date&results-per-page=$PER_PAGE"  | jq -r '.total_pages')
    echo $total_pages
    for (( i = 1; i <= $total_pages; i++ ))
    do
       cf curl "/v2/events?order-direction=desc&created_ats[gt]=$start_date&results-per-page=$PER_PAGE&page=$i" | jq -r '.resources[].entity |{timestamp,organization_guid,space_guid,actee_type,actee_name,actor_name,type,metadata} | to_entries | map(.value|tostring) |@csv' >> event.csv
    done
}

function init_csv(){
    echo "DATE,ORG,SPACE,ACTEE-TYPE,ACTEE-NAME,ACTOR,EVENT TYPE,DETAILS" > event.csv
}

function search_n_replace(){
    for key in ${!orgMap[*]}
    do
        #echo $key
        #echo ${orgMap[$key]}
        ##$sed -i 's@'"$kye"'@'"${orgMap[$key]}"'@g' event.csv 
        sed -i '' "s/$key/${orgMap[$key]}/g" event.csv 
    done
    for key in ${!spaceMap[*]}
    do
        #echo $key
        #echo ${spaceMap[$key]}
        ##$sed -i 's@'"$kye"'@'"${spaceMap[$key]}"'@g' event.csv 
        sed -i '' "s/$key/${spaceMap[$key]}/g" event.csv 
    done
}

today=$(date -u +"%Y-%m-%dT00:00:00Z")

init_org
init_space
init_csv
get_events "2022-08-12T16:41:00Z"
search_n_replace  
