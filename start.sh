#!/bin/bash

curl-impersonate() {
    curl-impersonate-chrome \
        --ciphers TLS_AES_128_GCM_SHA256,TLS_AES_256_GCM_SHA384,TLS_CHACHA20_POLY1305_SHA256,ECDHE-ECDSA-AES128-GCM-SHA256,ECDHE-RSA-AES128-GCM-SHA256,ECDHE-ECDSA-AES256-GCM-SHA384,ECDHE-RSA-AES256-GCM-SHA384,ECDHE-ECDSA-CHACHA20-POLY1305,ECDHE-RSA-CHACHA20-POLY1305,ECDHE-RSA-AES128-SHA,ECDHE-RSA-AES256-SHA,AES128-GCM-SHA256,AES256-GCM-SHA384,AES128-SHA,AES256-SHA \
        -H 'sec-ch-ua: "Chromium";v="116", "Not)A;Brand";v="24", "Google Chrome";v="116"' \
        -H 'sec-ch-ua-mobile: ?0' \
        -H 'sec-ch-ua-platform: "Windows"' \
        -H 'Upgrade-Insecure-Requests: 1' \
        -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36' \
        -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
        -H 'Sec-Fetch-Site: none' \
        -H 'Sec-Fetch-Mode: navigate' \
        -H 'Sec-Fetch-User: ?1' \
        -H 'Sec-Fetch-Dest: document' \
        -H 'Accept-Encoding: gzip, deflate, br' \
        -H 'Accept-Language: en-US,en;q=0.9' \
        --http2 --http2-no-server-push --compressed \
        --tlsv1.2 --alps --tls-permute-extensions \
        --cert-compression brotli \
        "$@"
}

download() {
    curl -L -s -o "$1" "$2"

    if [ "$?" -eq 0 ]; then
        echo "--> $1 has been successfully downloaded."
    else
        echo "--> Failed to download $1. Skipping..."
    fi
}

paper_download() {
    echo "Downloading Paper..."

    # Get download url
    Build=$(curl-impersonate -L -s "https://papermc.io/api/v2/projects/paper/versions/$Version" | jq -r '.builds[-1]')
    url="https://papermc.io/api/v2/projects/paper/versions/$Version/builds/$Build/downloads/paper-$Version-$Build.jar"

    download "$working_dir/paper.jar" "$url"
}

spigot_download() {
    echo "Downloading $2 from Spigot..."

    # Get download url
    url="https://api.spiget.org/v2/resources/$1/download"

    download "$working_dir/plugins/$2.jar" "$url"
}

bukkit_download() {
    echo "Downloading $2 from Bukkit..."

    # Get download url
    url="https://dev.bukkit.org/projects/$1/files/latest"

    download "$working_dir/plugins/$2.jar" "$url"
}

hangar_download() {
    echo "Downloading $2 from Hangar..."

    # Get download url
    wget_output=$(curl-impersonate -L -s "https://hangar.papermc.io/api/v1/projects/$1/versions?limit=1&offset=0&channel=Release&platform=PAPER")
    url=$(echo "$wget_output" | jq -r '.result[0].downloads.PAPER.downloadUrl')
    if [ "$url" = "null" ]; then
        url=$(echo "$wget_output" | jq -r '.result[0].downloads.PAPER.externalUrl')
    fi

    download "$working_dir/plugins/$2.jar" "$url"
}

github_download() {
    echo "Downloading $2 from Github..."

    # Get download url
    url=$(curl-impersonate -L -s "https://api.github.com/repos/$1/releases/latest" | jq -r '.assets[0].browser_download_url')

    download "$working_dir/plugins/$2.jar" "$url"
}

jenkins_download() {
    echo "Downloading $2 from Jenkins..."

    # Get download url
    wget_output=$(curl-impersonate -L -s "$1/lastSuccessfulBuild/api/json" | jq -r '.artifacts[0].relativePath')
    url="$1/lastSuccessfulBuild/artifact/$wget_output"

    download "$working_dir/plugins/$2.jar" "$url"
}

handle_plugins() {
    local type="$1"
    local id="$2"
    local name="$3"
    local enable="$4"

    case "$enable" in
    "true")
        case "$type" in
        "spigot")
            spigot_download "$id" "$name"
            ;;
        "bukkit")
            bukkit_download "$id" "$name"
            ;;
        "hangar")
            hangar_download "$id" "$name"
            ;;
        "github")
            github_download "$id" "$name"
            ;;
        "jenkins")
            jenkins_download "$id" "$name"
            ;;
        esac
        ;;
    "false")
        echo "$name is disabled. Deleting..."
        rm -f "$working_dir/plugins/$name.jar"
        if [ "$?" -eq 0 ]; then
            echo "--> $name has been deleted."
        else
            echo "--> Failed to delete $name. Skipping..."
        fi
        ;;
    esac
}

echo "------------------------------------"
echo "Minecraft Geyser server (doandat943)"

# Set server version
if [ -z "$Version" ]; then
    Version="$(curl-impersonate -L -s "https://api.papermc.io/v2/projects/paper" | jq -r '.versions[-1]')"
else
    Version="$Version"
fi
echo "Version: $Version"

# Set server port
if [ -z "$Port" ]; then
    Port="25565"
fi
echo "Port: $Port"

echo "------------------------------------"

# Set working dir
working_dir="/minecraft"

# Download Paper
paper_download

# Download plugins
plugins=$(cat "$working_dir/plugins/.plugins.json")

for type in spigot bukkit hangar github jenkins; do
    for item in $(echo "$plugins" | jq -c ".$type[]"); do
        id=$(echo "$item" | jq -r '.id')
        name=$(echo "$item" | jq -r '.name')
        enable=$(echo "$item" | jq -r '.enable')

        handle_plugins "$type" "$id" "$name" "$enable"
    done
done

# Update server config
if [ -f "$working_dir/server.properties" ]; then
    sed -i "s/^online-mode=.*/online-mode=false/" "$working_dir/server.properties"
    sed -i "s/^server-port=.*/server-port=$Port/" "$working_dir/server.properties"
    sed -i "s/^query\.port=.*/query\.port=$Port/" "$working_dir/server.properties"
fi

# Update Geyser config
if [ -f "$working_dir/plugins/Geyser-Spigot/config.yml" ]; then
    sed -i "s/^ *clone-remote-port: .*/  clone-remote-port: true/" "$working_dir/plugins/Geyser-Spigot/config.yml"
    sed -i "s/^ *auth-type: .*/  auth-type: offline/" "$working_dir/plugins/Geyser-Spigot/config.yml"
    sed -i "s/^ *port: .*/  port: $Port/" "$working_dir/plugins/Geyser-Spigot/config.yml"
fi

# Start server
echo "Starting Minecraft server..."
cd $working_dir
java -jar paper.jar --nogui

# Accept EULA
if grep -q "eula=false" "$working_dir/eula.txt"; then
    mv /server-icon.png "$working_dir/"
    mv /plugins.json "$working_dir/plugins/.plugins.json"
    echo "eula=true" >"$working_dir/eula.txt"
    sed -i "s/^motd=.*/motd=§6Minecraft §eGeyser §c❤/" "$working_dir/server.properties"
fi

# Exit container
exit 0
