# Add the location of the postgresql client tools installed by apt to `PATH`.
# If you don't add the direct path to the binaries, `pg_wrapper` will get involved and **not work**.
# This is because `pg_wrapper` is installed in `/home/vcap/deps/0/apt/usr/lib/postgresql/13/bin` by apt-buildpack, but Ubuntu expects them to be in `/usr/lib/postgresql/15/bin`.
export PATH="${HOME}/deps/0/apt/usr/lib/postgresql/15/bin:${PATH}"

# Create a .pgpass file with the credentials from the VCAP_SERVICES environment variable.
if [ "$(jq -r 'has("aws-rds")' <<< "$VCAP_SERVICES")" == "true" ]; then
    rm -f "${HOME}/.pgpass"

    for item in $(jq -r '.["aws-rds"][] | @base64' <<< "$VCAP_SERVICES"); do
        _get_credential() {
            echo "$item" | base64 --decode | jq -r ".credentials.${1}"
        }

        host=$(_get_credential "HOST")
        port=$(_get_credential "PORT")
        database=$(_get_credential "DB_NAME")
        username=$(_get_credential "USERNAME")
        password=$(_get_credential "PASSWORD")

        echo "${host}:${port}:${database}:${username}:${password}" >> "${HOME}/.pgpass"
    done
fi
