# -----------------------------------------------------------------------------
# written by:   lawrence mcdaniel
#               https://lawrencemcdaniel.com
#
# date:         jul-2024
#
# usage:        install tutor Koa 
# -----------------------------------------------------------------------------

~/scripts/docker-init.sh


# 5. Setup your local tutor environment
#
# choose the initial version of tutor to install.
# you should select the version of tutor that natively installs
# the open edx version of your immediate next upgrade. for example,
# if you're currently running Koa then you should should install
# tutor 12.2.0 which natively installs Lilac, the immediate next version
# of open edx after Koa.
#
# keep in mind that during this step you're creating a throwaway local
# instance of open edx that effectively is a bi-product of you getting
# your local tutor environment into the state that you need so that you can
# begin migrating your data.
#
# -----------------------------------------------------------------------------
# see: https://discuss.openedx.org/t/how-to-move-through-tutor-versions/6618
#      https://discuss.openedx.org/t/how-to-move-through-tutor-versions-part-ii/9574
#
# Curr edX            will
# Version   tutor     upgrade to
# --------  --------- -------------
# Juniper   11.3.0    → Koa
# Koa       12.2.0    → Lilac
# Lilac     13.3.1    → Maple
# Maple     14.2.4    → Nutmeg
#
# note: prior versions of tutor were yanked, and so the earliest version you can migrate to is Lilac
#
#
# run only if you're migrating from juniper
# pip install "tutor[full]==11.3.0"       # installs/upgrades to Koa by default
# tutor local quickstart

# run only if you're migrating from koa
pip install "tutor[full]==12.2.0"       # installs/upgrades to Lilac by default
pip install --upgrade setuptools
tutor local quickstart
