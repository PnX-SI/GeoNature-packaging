
# Créer un dépôt apt

Procédure traduite et synthétisée depuis 

## S'assurer d'avoir une clé pgp

Le dépot sera signé avec une clé pgp. Pour cela, il faudra 3 fichiers:

- un fichier contenant la clé privée maitresse, qu'il faut garder secrete
- un fichier contenant la clé publique, qu'on peut partager
- un fichier contenant la clé de signature, qu'on mettra sur le serveur

L'ID de la clé doit être uploadée sur un serveur de clés publique, et les fichiers doivent être conservés de manière sécurisée, hors ligne.

Ces fichiers ont déjà été créé, et kevin devrait vous les avoir transmis (key ID 45043FBE4CB3A678, uploadée sur keyserver.ubuntu.com). Si ce pas le cas, on peut en créé de nouveau en suivant la procédure ici: https://www.digitalocean.com/community/tutorials/how-to-use-reprepro-for-a-secure-package-repository-on-ubuntu-14-04

## Mettre les clés sur le serveur

Uploader les fichiers de clés publique et de signature sur le serveur, et les importer dans gpg une fois sur le serveur:

```bash
gpg --import public.key signing.key
```

Les clés doivent apparaitre si on fait ceci sur le serveur:

```bash
gpg --list-secret-keys
sec#  rsa4096 2020-03-10 [SC]
      A46EDFCA06DA699FBF3F1FCE45043FBE4CB3A678
uid           [ultimate] PnX-SI <geonature@ecrins-parcnational.fr>
ssb   rsa4096 2020-03-10 [E]
ssb   rsa4096 2020-03-10 [S]
```

Le # est important, ça veut dire que la clé privée n'est PAS sur le serveur, ce qui est le but.

## Créer l'arboresence pour le dépôt

Toujours sur le serveur, installer les dépendances:

```bash
sudo apt-get install reprepro debhelper
```

Faire un dossier ou on va mettre le repository. On peut le mettre où on veut, ici je le mets dans /var/www/apt/:

```bash
sudo mkdir -p /var/www/apt/conf
# on se donne les droits en écriture, et apache en lecture
owner=$USER  
sudo chown -R "$owner:www-data" /var/www/deb/ 
sudo chmod -R 755  /var/www/apt/
```

Puis on edite un fichier de configuration:

```bash
cd /var/www/apt/conf
touch options distributions # options restera vide
nano distributions
```

Le fichier distributions va contenir la liste des distributions debian et ubuntu qu'on veut supporter:

```
Label: deb.geonature.fr
Codename: stretch
Components: main
Architectures: amd64
SignWith: 45043FBE4CB3A678

Label: deb.geonature.fr
Codename: buster
Components: main
Architectures: amd64
SignWith: 45043FBE4CB3A678

Label: deb.geonature.fr
Codename: bionic
Components: main
Architectures: amd64
SignWith: 45043FBE4CB3A678

Label: deb.geonature.fr
Codename: xenial
Components: main
Architectures: amd64
SignWith: 45043FBE4CB3A678
```


SignWith est l'id de notre clé publique qui va servir signer les dépôt. Components est soit main, contrib ou non-free, mettre toujours main pour les depôts aussi simple ça suffit.

## Ajouter run fichier deb au repo

```bash
reprepro -b <repo> includedeb <distrib> <package_file>
```

Ex, après avoir uploadé usershub_0.0.1-1_amd64.deb sur le serveur dans un dossier temporaire:


```bash
reprepro -b <repo> includedeb stretch usershub_0.0.1-1_amd64.deb
```

## Lister les fichiers du repo

```bash
reprepro -b /var/repositories/ list <distrib>
```

Ex, après avoir uploadé usershub_0.0.1-1_amd64.deb sur le serveur dans un dossier temporaire:

```bash
reprepro -b /var/www/deb/ list stretch
```

## Supprimer les fichiers du repo

```bash
reprepro -b <repo> remove <distrib> <package_name>
```

Ex:

```bash
reprepro -b /var/www/deb/ remove stretch usershub
```

## Render le depôt publique

Il faut et il suffit d'exposer la racine du repository avec un serveur web (éviter tout de meme de servir les fichiers de conf).

Exemple de configuration apache possible:


```
<VirtualHost *:1234>
        ServerName 178.32.193.151 (ip du serveur ou un nom de sous domaine type deb.geonature.fr si possible, car dans ce cas on peut mettre le port 80)
        DocumentRoot /var/www/deb/

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined

        <Directory /var/www/deb/ >
                Options Indexes FollowSymLinks Multiviews
                Order allow,deny
                Allow from all
        </Directory>

        <Directory "/var/www/deb/apt/*/db/">
                Order deny,allow
                Deny from all
        </Directory>

        <Directory "/var/www/deb/apt/*/conf/">
                Order deny,allow
                Deny from all
        </Directory>

        <Directory "/var/www/deb/apt/*/incoming/">
                Order allow,deny
                Deny from all
        </Directory>
</VirtualHost>
```

## Installer les paquets depuis le depot

Faire confiance à la clé de chiffrement du serveur:

```bash
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4CB3A678
```

S'assurer qu'on peut ajouter un depôt (normalement pas nécessaire, mais dans le doute):

sudo apt-get install software-properties-common

Ajouter le dépôt du serveur à ses sources:

```bash
sudo add-apt-repository "deb http://<server> <distrib> main"
```

Ex:

```bash
sudo add-apt-repository "deb http://178.32.193.151:1234/ stretch main"
```

Ou:

Ex:

```bash
sudo add-apt-repository "deb http://deb.geonature.fr/ stretch main"
```

Selon la config.

Et ça s'installe:

```bash
sudo apt-get install usershub
```
