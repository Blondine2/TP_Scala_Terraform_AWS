# TP_Scala_Terraform_AWS
Ce projet contient un code terraform qui crée l'architecture de toute la chaîne définie dans le diagramme d'architecture . 
Il contient également un projet scala daont le but est de détecter les utilisateurs qui ont posté sur twitter pendant les 60 dernières secondes.
ces données sont stockées dans un bucket s3 via des flux de données et de diffusion, puis seront récupérées via un crawler pour être analysé avec des requêtes Athena.
le résultat de ce processus sera stocké sur un bucket s3 que l'utilisateur pourra consulter.

#Préréquis
*Posséder un compte AWS
*Posséder des crédentials de connection à AWS
*Posséder des crédentials de connection à l'API Twitter

#Pour lancer la création de l'infrastructure AWS, exécutez les commandes suivantes : 
 * $Terraform init
 * $Terraform plan
 * $Terraform apply
 
Toute l'infrastructure est alors créé, elle comprends : 
- le VPC
- le subnet
- l'internet gateway
- l'instance EC2 et sa table de routage
- les groupes, rôles et policies associés
- le data stream
- le firehose 
- les buckets s3 
- l'analysateur et son role associé
- la base de données Athena

Toutes ces infrastructures sont créés sur la zone de disponibilité de Franckfort(eu-central-1)

#Le code scala est nommé TwitterApiAuthors : il permet d'une part de se connecter à l'api Twitter pour avoir accès aux tweets en temps réels des utilisateurs.
le but de ce code est de récupérer le utilisateurs qui ont le plus twittés durant les 60 dernières secondes et de compter leurs tweets.Ces informations(Nom de l'utilisateur + le nombre de tweets qu'il a envoyés) sont récupérés progressivement, 
puis sont stockés dans le datastream(AppstreamData); Ensuite, le firehose(AppDataFirehose) récupère ces informations qu'il stocke dans le bucket s3(apiscalabucket).
une fois lancé, le crawler récupère les données du s3 et les enregistre dans la base de données (authorsdata). De cette base on peut effectuer des requêtes sur Athena en regroupant les utilisateurs par ordre de tweets croissants.
ces résultats seront alors stockés dans le bucket apiauthorsresult.
 
pour compiler et packager le projet TwitterApiAuthors, exécutez les commandes suivantes :
* $sbt clean compile
* $sbt package

Remarque : Pour des raisons de sécurité, je vais masquer mes crédentials de connexion à AWS.
