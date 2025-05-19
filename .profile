# Add the location of the postgresql client tools installed by apt to `PATH`.
# If you don't add the direct path to the binaries, `pg_wrapper` will get involved and **not work**.
# This is because `pg_wrapper` is installed in `/home/vcap/deps/0/apt/usr/lib/postgresql/13/bin` by apt-buildpack, but Ubuntu expects them to be in `/usr/lib/postgresql/15/bin`.
export PATH="/home/vcap/deps/0/apt/usr/lib/postgresql/15/bin:${PATH}"

# Create a .pgpass file with the credentials from the VCAP_SERVICES environment variable.
if [ "$(jq -r 'has("aws-rds")' <<< "$VCAP_SERVICES")" == "true" ]; then
    rm -f "${HOME}/.pgpass"

    for item in $(jq -r '.["aws-rds"][] | @base64' <<< "$VCAP_SERVICES"); do
        _get_credential() {
            echo "$item" | base64 --decode | jq -r ".credentials.${1}"
        }

        host=$(_get_credential "host")
        port=$(_get_credential "port")
        database=$(_get_credential "db_name")
        username=$(_get_credential "username")
        password=$(_get_credential "password")

        echo "${host}:${port}:${database}:${username}:${password}" >> "${HOME}/.pgpass"
    done

    chmod 600 "${HOME}/.pgpass"
fi

# Check if aws cli is installed and install if not found
if ! command -v aws &> /dev/null
then
    echo "Installing the latest aws cli"

    echo "Downloading the latest aws cli"

    # Download the aws cli and redirect stderr to /dev/null
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" 2> /dev/null
    unzip awscliv2.zip > /dev/null

    # Install the aws cli and redirect the output to /dev/null
    echo "Running the aws cli installer"
    ./aws/install --install-dir ~/aws-cli --bin-dir ~/bin > /dev/null

    # Remove installation files
    echo "Removing installation files"
    rm -rf awscliv2.zip aws
fi
