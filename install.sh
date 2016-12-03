#!/bin/bash


PYPI_INDEX=""
BUILDOUT_INDEX=""

HELP=0

#
# We need bash
#
if [ -z "$BASH_VERSION" ]; then
    echo -e "Error: BASH shell is required !"
    exit 1
fi

#
# install_openerp
#
function install_openerp {
    # TODO: Rework this test
    if [ -d py27 ]; then
        echo "install.sh has already been launched."
        echo "So you must either use bin/buildout to update or launch \"install.sh reset\" to remove all buildout installed items."
        exit -1
    fi
    if [ ! -f bootstrap.py ]; then    
        wget https://raw.github.com/buildout/buildout/master/bootstrap/bootstrap.py
    fi
    virtualenv py27
    py27/bin/python bootstrap.py
    py27/bin/pip install $PYPI_INDEX bzr==2.7.0
    py27/bin/pip install $PYPI_INDEX cython==0.25.1
    bin/buildout install
    echo
    echo "Your commands are now available in ./bin"
    echo "Python is in ./py27. Don't forget to launch source py27/bin/activate"
    echo 
}

function remove_buildout_files {
    echo "Removing all buidout generated items..."
    echo "    Not removing downloads/ to avoid re-downloading openerp"
    rm -rf .installed.cfg
    rm -rf bin/
    rm -rf develop-eggs/
    rm -rf eggs/
    rm -rf etc/
    rm -rf py27/
    rm -rf bootstrap.py
    echo "    Done."
}

function setup_c9_trusty_blank_container {
    
    # Set a UTF8 locale
    sudo locale-gen fr_FR fr_FR.UTF-8
    sudo update-locale    


    # Update bashrc with locale if needed
    if grep -Fxq "# Added by appserver-templatev10 install.sh" /home/$USER/.bashrc ; then
        echo "Skipping /home/$USER/.bashrc update"
    else
        cat >> /home/ubuntu/.bashrc <<EOT
#
# Added by appserver-templatev10 install.sh
export LANG=fr_FR.UTF-8
export LANGUAGE=fr_FR
export LC_ALL=fr_FR.UTF-8
export LC_CTYPE=fr_FR.UTF-8

EOT
    fi

    # Refresh index and install required index
    sudo apt-get update
    sudo apt-get install -y libsasl2-dev python-dev libldap2-dev libssl-dev
    sudo apt-get install -y postgresql
    sudo pg_dropcluster 9.3 main
    sudo pg_createcluster --locale fr_FR.UTF-8 9.3 main
    sudo pg_ctlcluster 9.3 main start
    sudo su - postgres -c "psql -c \"CREATE ROLE ubuntu WITH LOGIN SUPERUSER CREATEDB CREATEROLE PASSWORD 'ubuntu';\"" 
    sudo su - postgres -c "psql -c \"CREATE DATABASE ubuntu;\"" 
    
    # Install recent setuptools
    wget https://bootstrap.pypa.io/ez_setup.py
    sudo python ez_setup.py
    rm ez_setup.py
    sudo rm setuptools-*.zip 
    
    # Install recent virtualenv
    sudo easy_install virtualenv
    
    # create a basic buildout.cfg if none is found
    if [ ! -f buildout.cfg ]; then    
        cat >> buildout.cfg <<EOT 
[buildout]
extends = appserver.cfg

[openerp]
options.admin_passwd = admin
options.db_user = ubuntu
options.db_password = ubuntu
options.db_host = 127.0.0.1
options.xmlrpc_port = 8080    
EOT
    fi    
    
    # lessc and plugin
    sudo npm install -g less less-plugin-clean-css
    sudo ln -fs /usr/local/bin/lessc /usr/bin/lessc

}


function setup_xenial {
    
    # Set a UTF8 locale
    sudo locale-gen fr_FR fr_FR.UTF-8
    sudo update-locale    
    
    # Update bashrc with locale if needed
    if grep -Fxq "# Added by appserver-templatev10 install.sh" /home/$USER/.bashrc ; then
        echo "Skipping /home/$USER/.bashrc update"
    else
        cat >> /home/ubuntu/.bashrc <<EOT
#
# Added by appserver-templatev10 install.sh
export LANG=fr_FR.UTF-8
export LANGUAGE=fr_FR
export LC_ALL=fr_FR.UTF-8
export LC_CTYPE=fr_FR.UTF-8
EOT
    fi
    
    # Refresh index and install required index
    sudo apt-get update
    sudo apt-get install -y libsasl2-dev python-dev libldap2-dev libssl-dev
    

    sudo apt install -y libz-dev gcc
    sudo apt install -y libxml2-dev libxslt1-dev
    sudo apt install -y libpq-dev
    sudo apt install -y libldap2-dev libsasl2-dev
    sudo apt install -y libjpeg-dev libfreetype6-dev liblcms2-dev
    sudo apt install -y libopenjpeg5 libopenjpeg-dev
    sudo apt install -y libwebp5  libwebp-dev
    sudo apt install -y libtiff-dev
    sudo apt install -y libyaml-dev
    sudo apt install -y bzr mercurial git
    sudo apt install -y curl htop vim tmux
    sudo apt install -y supervisor

    # Install postgresql
    sudo apt-get install -y postgresql
    sudo pg_dropcluster --stop 9.5 main
    sudo pg_createcluster --locale fr_FR.UTF-8 9.5 main
    sudo pg_ctlcluster 9.5 main start
    sudo su - postgres -c "psql -c \"CREATE ROLE ubuntu WITH LOGIN SUPERUSER CREATEDB CREATEROLE PASSWORD 'ubuntu';\"" 
    sudo su - postgres -c "psql -c \"CREATE DATABASE ubuntu;\"" 
    
    # Install virtualenv
    sudo apt-get install -y python-virtualenv

    if [ ! -f buildout.cfg ]; then    
        cat >> buildout.cfg <<EOT 
[buildout]
extends = appserver.cfg

[openerp]
options.admin_passwd = admin
options.db_user = ubuntu
options.db_password = ubuntu
options.db_host = 127.0.0.1
options.xmlrpc_port = 8080    
EOT
    fi

    # Install Odoo 9 dependencies
    # sudo apt-get install -y nodejs npm => Already installed as a c9 prerequisites
    sudo apt install -y nodejs npm
    sudo ln -fs /usr/bin/nodejs /usr/bin/node    
    sudo npm install -g less less-plugin-clean-css
    sudo ln -fs /usr/local/bin/lessc /usr/bin/lessc
    sudo wget http://download.gna.org/wkhtmltopdf/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb
    sudo apt-get install -y fontconfig libxrender1 libjpeg-turbo8
    sudo dpkg -i wkhtmltox-0.12.1_linux-trusty-amd64.deb
    sudo rm wkhtmltox-0.12.1_linux-trusty-amd64.deb
}

#
# install xy required dependencies
#
function install_dependencies {
    
    # Install Poppler utils (used for text extraction from PDF)
    echo "Installing Poppler Utils (from source)"
    wget https://poppler.freedesktop.org/poppler-0.48.0.tar.xz
    tar -xf poppler-0.48.0.tar.xz
    cd poppler-0.48.0
    ./configure
    make
    make check
    sudo make install
    sudo ldconfig
    cd ..
    rm poppler-0.48.0.tar.xz
    rm -rf poppler-0.48.0

    # Install tesseract OCR
    echo "Installing Tesseract-OCR (from distribution)"
    sudo apt install -y tesseract-ocr tesseract-ocr-fra
    
    #  Install Magicwand
    echo "Installing Magicwand (from distribution)"
    sudo apt install -y libmagickwand-dev
}


#
# Placeholder function used to debug snippets
#
function debug_function {
    

    # Update LD_LIBRARY_PATH on Cloud 9
    if grep -Fxq "# Added by Xy dependencies Installer" /home/$USER/.profile
    then
        echo "Skipping /home/$USER/.profile update"
    else
        cat >> /home/$USER/.profile <<'EOT'

# Added by Xy dependencies Installer
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

EOT
    fi
    
}


#
# Process command line options
#
while getopts "i:h" opt; do
    case $opt in
        i)
            PYPI_INDEX="-i ${OPTARG}"
            BUILDOUT_INDEX="index = ${OPTARG}"
            ;;

        h)
            HELP=1
            ;;

        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;

        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

COMMAND=${@:$OPTIND:1}

echo
echo "install.sh - Inouk OpenERP Buildout Installer"
echo "(c) 2013, 2014, 2015, 2016 @cmorisse"

if [[ $COMMAND == "help"  ||  $HELP == 1 ]]; then
    echo "Available commands:"
    echo "  ./install.sh help              Prints this message."
    echo "  ./install.sh [-i ...] openerp  Install OpenERP using buildout (prerequisites must be installed)."
    echo "  ./install.sh dependencies      Install dependencies specific to this server."
    echo "  ./install.sh c9-trusty         Install Prerequisites on a Cloud9 Ubuntu 14 blank container."
    echo "  ./install.sh xenial            Install Prerequisites on a fresh Ubuntu Xenial."
    echo "  ./install.sh reset             Remove all buildout installed files."
    echo 
    echo "Available options:"
    echo "  -i   Pypi Index to use (default=""). See pip install --help"
    echo "  -h   Prints this message"
    echo 
    exit
fi

if [[ $COMMAND == "reset" ]]; then
    remove_buildout_files
    exit
elif [[ $COMMAND == "openerp" ]]; then
    install_openerp
    exit
elif [[ $COMMAND == "c9-trusty" ]]; then
    setup_c9_trusty_blank_container
    exit
elif [[ $COMMAND == "xenial" ]]; then
    setup_xenial
    exit
elif [[ $COMMAND == "dependencies" ]]; then
    install_dependencies
    exit
elif [[ $COMMAND == "debug" ]]; then
    debug_function
    exit
fi

echo "use ./install.sh -h for usage instructions."