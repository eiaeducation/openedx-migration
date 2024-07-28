# -----------------------------------------------------------------------------
# 4. initialize Docker and tutor environments
#
# Note that in my case I had to run this procedure a half dozen times
# until it actually worked. If you're as unfortunate as me then you'll
# potentially need to get your ubuntu instance back to a pristine state
# depending on what went wrong on your most recent failed attempt.
#
# This is how to "reset" your Ubuntu environment to pristine.
#
# - shut down and remove any running Docker containers
# - delete any existing Docker volumes
# - if tutor is currently installed then uninstall it and all of its modules
# -----------------------------------------------------------------------------
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker rmi $(docker images -a -q)
docker volume prune

sudo rm -rf "$(tutor config printroot)"
pip uninstall tutor-openedx
sudo rm "$(which tutor)"
pip uninstall tutor -y
pip uninstall tutor-xqueue -y
pip uninstall tutor-webui -y
pip uninstall tutor-richie -y
pip uninstall tutor-notes -y
pip uninstall tutor-minio -y
pip uninstall tutor-mfe -y
pip uninstall tutor-license -y
pip uninstall tutor-forum -y
pip uninstall tutor-ecommerce -y
pip uninstall tutor-discovery -y
pip uninstall tutor-android -y
# additional tutor pip packages -- new to v18
pip uninstall tutor-cairn -y
pip uninstall tutor-credentials -y
pip uninstall tutor-indigo -y
pip uninstall tutor-jupyter -y
