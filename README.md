# argocd-hybrid
This Repo describes steps to install Apigee hybrid with helm charts using ArgoCD in a gitOps style fashion.
on a GKE cluster.

It also contains cert-manager, nginx, and vault setup on the cluster

![Screenshot 2023-10-21 at 10 47 52 AM](https://github.com/AyoSal/argocd-hybrid/assets/27664278/e45fe8e9-7d61-4466-909c-bb5d0351abb0)


First follow the steps in part 1 to enable required APIs, create your Apigee organization, environment and environment group at this [page](https://cloud.google.com/apigee/docs/hybrid/v1.10/precog-overview).

Create your GKE cluster by following the commands from this [page](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create) as below.

```
gcloud container clusters create argocd-1103
```

Also ensure you add 2 nodegroups as required for apigee-hybrid cluster as per documentation at this [page](https://cloud.google.com/apigee/docs/hybrid/v1.10/install-create-cluster#gke).

Once your cluster is created, use the below command to gain access to your cluster 

```
gcloud container clusters get-credentials argocd-1103 --region us-east4 --project ayos-os-test
```

Enable synchroniser access ( pre-requisite for installing Apigee hybrid)

```
export TOKEN=$(gcloud auth print-access-token)

curl -X POST -H "Authorization: Bearer $TOKEN " -H "Content-Type:application/json" "https://apigee.googleapis.com/v1/organizations/
ORG_NAME:getSyncAuthorization" -d ''
```

Pull the apigee-hybrid helm charts to a local folder as below

```
export CHART_REPO=oci://us-docker.pkg.dev/apigee-release/apigee-hybrid-helm-charts
export CHART_VERSION=1.10.3
helm pull $CHART_REPO/apigee-operator --version $CHART_VERSION --untar
helm pull $CHART_REPO/apigee-datastore --version $CHART_VERSION --untar
helm pull $CHART_REPO/apigee-env --version $CHART_VERSION --untar
helm pull $CHART_REPO/apigee-ingress-manager --version $CHART_VERSION --untar
helm pull $CHART_REPO/apigee-org --version $CHART_VERSION --untar
helm pull $CHART_REPO/apigee-redis --version $CHART_VERSION --untar
helm pull $CHART_REPO/apigee-telemetry --version $CHART_VERSION --untar
helm pull $CHART_REPO/apigee-virtualhost --version $CHART_VERSION --untar
```

Install the Apigee CRDs as follows  from within the folder where the charts above are located

Use the dry-run feature by running the following command

```
kubectl apply -k  apigee-operator/etc/crds/default/ --server-side --force-conflicts --validate=false --dry-run=server
```

After validating with dry-run command, create the crd’s by applying as below 

```
kubectl apply -k  apigee-operator/etc/crds/default/ --server-side --force-conflicts --validate=false
```

Create the apigee namespace

```
kubectl create namespace apigee
```

Create the kubernetes secret for the serviceaccounts for the various Apigee hybrid components 

```
kubectl create secret generic SECRET_NAME  --from-file="client_secret.json=SA_FILE_NAME.json"  -n apigee
```


Also create the kubernetes secret for the Apigee hybrid ingress with TLS certificates

```
kubectl create secret generic SECRET-NAME  --from-file="cert=PATH_TO_CRT_FILE"  --from-file="key=PATH_TO_KEY_FILE"  -n apigee
```

Pull this repo which already has the charts as well as the templates and manifests files required


With this repo, we create ArgoCD applications for all the apigee hybrid components and a few others.

We achieve this by making use of the app of apps pattern. 
The App of Apps Pattern lets us define a root ArgoCD Application ( in this case named apigeehybrid) which we define in the apps.yaml file at the root of the repo.  Rather than point to an application manifest, the Root App points to a folder ( in this case /apps) which contains the templates folder containing the Application YAML definition for each microservice that’s part of the app bundle (Child Apps). Each microservice’s Application YAML then points to a directory containing the application manifests ( in this case /apps/apigee-charts/”respective chart folder”). 

The various components that get installed as helm charts from the repo and as ArgoCD applications include 
* Item 1 apigeehybrid
* Item 2 cert-manager 
* Item 3 apigee-operator
* Item 4 apigee-datastore
* Item 5 apigee-telemetry
* Item 6 apigee-redis
* Item 7 apigee-ingress-manager
* Item 8 Apigee-org
* Item 9 Apigee-environment
* Item 10 Apigee-virtualhost
* Item 11 Secret store csi driver
* Item 12 vault



Below shows the file structure of the repo, lets discuss on the components that get installed with this repo and how you can modify them to make adjustments.

![Screenshot 2023-11-08 at 9 25 07 PM](https://github.com/AyoSal/argocd-hybrid/assets/27664278/4bda256a-bff6-4be6-abae-4d045d27aa0c)


We will now take each component and discuss them one after the other

For each component we have a helm chart folder within the apigee-charts folder. This folder contains a custom values file which is used to apply configuration changes custom or specific to our apigee hybrid setup

For example, for apigee-datastore component we have a folder call apigee-datastore located at /apps/apigee-datastore, which contains the helm charts for apigee datastore as well as a base values file and also a customised values file called apigee-ds.yaml which contains values that are specific to configure the apigee datastore pds and resources as we require and will override the basic installation. We also have a file called datastore.yaml located in the /apps/templates folder which serves as a template for the Argocd application for the apigee-datastore which will be managed by the apigeehybrid application which serves as the umbrella ArgoCD application.


To modify or customise the setup of the ArgoCD applications for each component  make changes to the following files
 Within the /apps/templates folder
Modify the apigee-env1.yaml file with the name of the custom values file and a parameter for the name of the environment 
Modify the apigee-vhost.yaml file with the name of the custom values file and a parameter for the name of the environment group
Repeat the modification process for all the components to state the name of the custom values file.

To customise the hybrid components with custom split overrides modify the custom values files for each component within the apps/ folder as follows

Modify the apps/apigee-datastore/values-ds.yaml file with the number of replicas, nodeselection, with the number of replicas required, memory, cpu, if backup is to be enabled
Modify the apps/apigee-virtualhost
Modify the apps/telemetry
Modify the apps/redis
Modify the apps/apiee-env
Modify the apps/apigee-operator
Modify the apps/apigee-ingress-manager
Modify the apps/apigee-org




We now have all the components to install apigee hybrid with helm charts ready.
Create the ArgoCD namespace 
```
  kubectl create ns argocd
```

Install ArgoCD into your cluster
```
 kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```


Patch Argocd service from ClusterIP to loadbalancer 
```
kubectl -n argocd patch svc argocd-server --type='json' -p '[{"op":"replace","path":"/spec/type","value":"LoadBalancer"}]'
```

Retrieve the initial password for Argo cd with -

```
 argocd admin initial-password -n argocd
```

Retrieve the external IP of the ArgoCD service and use that to log into the ArgoCD UI with the initial password received above, change this password to one of your choice. 

Re-login with your new password.

Click on settings tile and connect to git repo. Create repositories required for ArgoCD to pull the helm charts of the components, 

![Screenshot 2023-11-08 at 9 57 41 PM](https://github.com/AyoSal/argocd-hybrid/assets/27664278/7cb9c7b4-c1b4-4f89-b3d2-19c63f346205)


For connecting the gitHub repo to ArgoCD, you may need to generate ssh keys and share between github and ArgoCD.
Once the repo is created successfully, you will see a green tick as shown below.

![Screenshot 2023-11-08 at 10 00 18 PM](https://github.com/AyoSal/argocd-hybrid/assets/27664278/dde4133f-2e9e-40f0-83b6-ddea8dc05813)


Repeat the process to create repositories for  cert-manager, secrets store driver and Hashicorp vault


Deploying Applications to ArgoCD

After the repo’s are created we can now trigger build of the applications. During the sync of the applications between the github repo and Argocd the templates are first rendered into manifests and then created as ArgoCD applications which will then be used to trigger creation of the actual kubernetes resources in the gke cluster we created earlier.

We create the first ArgoCD application - apigeehybrid by running the below command from cli within the cluster

```
kubectl apply -f apps.yaml -n argocd
```

This will create the apigeehybrid argocd application as follows

![Screenshot 2023-11-08 at 10 07 17 PM](https://github.com/AyoSal/argocd-hybrid/assets/27664278/97948558-a9f3-4e98-aab1-0501e1b23a56)

Once this is created and verified in the UI you should also see the apigeehybrid ArgoCD Application in the ArgoCD UI as well as below.

![Screenshot 2023-11-08 at 10 08 30 PM](https://github.com/AyoSal/argocd-hybrid/assets/27664278/57909bd3-89b1-4964-a459-a74615af5eb8)

Once this is created and in synced status, we are ready to create the numerous Apigee hybrid components.

If you have auto-sync enabled, whenever you commit a change to your github repo, this will trigger a sync and Argocd will look to compare the state of the resources in the kubernetes cluster with that of the templates in the github repository in a gitops style fashion.

The Apigee hybrid subcomponents will automatically get picked from the github repo and create the argocd application for each of the components and the underlying kubernetes resources for each of the applications from their charts.

This process will take some time as it goes in to create the resources. To ensure the resources are created in the right order, we can define sync waves, which will ensure the components are spun up in the order we desire.  We do this by adding in an annotation in the template for each of the components as shown below.

![Screenshot 2023-11-08 at 10 15 55 PM](https://github.com/AyoSal/argocd-hybrid/assets/27664278/6f7fcf83-ef6b-4c2b-935a-72e0152bdd25)

Below shows the hierarchy of applications deployed by the  apigeehybrid argocd application

![Screenshot 2023-11-08 at 10 21 21 PM](https://github.com/AyoSal/argocd-hybrid/assets/27664278/5485a26f-aff6-44d5-ba4c-545a47fd2a11)


Below shows a view of all the apigee hybrid components as ArgoCD applications when fully deployed.

![Screenshot 2023-11-08 at 10 27 38 PM](https://github.com/AyoSal/argocd-hybrid/assets/27664278/bb21db99-e042-4a5c-ae2e-32034b7a2aca)



Other Approaches with ArgoCD

When deploying Apigee Helm charts with ArgoCD, there are several different approaches we can take. We can create ArgoCD Applications to point to the Helm repo and a separate repo for overrides.yaml files. Here is a sample ArgoCD application that deploys Apigee Operator from the Helm chart repo and pulls the values file from a Git repo’s dev branch:


```
API Version:  argoproj.io/v1alpha1
Kind:         Application
Name:         apigee-operator
Namespace:    default
Spec:
  Destination:
    Namespace:  apigee-system
    Server:     https://kubernetes.default.svc
  Project:      apigee
  Sources:
    Chart:  apigee-operator
    Helm:
      Value Files:
        $values/overrides.yaml
    Repo URL:         us-docker.pkg.dev/apigee-release/apigee-hybrid-helm-charts
    Target Revision:  1.0.0
    Ref:              values
    Repo URL:         git@github.com:/testrepo/apigee-argo.git
    Target Revision:  dev

```

We can also create an ApplicationSet to orchestrate the multiple helm charts deployment, leverage `waves` to group the Apigee helm charts into different order in deployments. However, this is more complicated and requires careful planning and execution.

Another approach to manage the Helm charts deployment is to use Helmfile (githb.com/helmfile/helmfile), which is a declarative spec for deploying Helm charts. It can be used to generate all-in-one manifests from the Helm charts and input values, for use with ArgoCD or other Kubernetes continuous deployment tools.

The benefits of Helmfile approach is to separate the configuration from the charts and environments. 

A sample Helmfile looks like this:


```
# helmfile example
# change the chart `version` as needed. Currently, below example uses 1.10.3
repositories:
- name: apigee-hybrid-helm-charts
  url: us-docker.pkg.dev/apigee-release/apigee-hybrid-helm-charts
  oci: true

---
releases:
- name: operator
  namespace: apigee-system
  chart: apigee-hybrid-helm-charts/apigee-operator
  version: 1.10.3
  values:
  - overrides.yaml

- name: datastore
  namespace: apigee
  chart: apigee-hybrid-helm-charts/apigee-datastore
  version: 1.10.3
  needs:
  - apigee-system/operator
  values:
  - overrides.yaml

... ...

- name: apigee-hybrid-proj # replace with the org name
  namespace: apigee
  chart: apigee-hybrid-helm-charts/apigee-org
  version: 1.10.3
  needs:
  - datastore
  - telemetry
  - redis
  - ingress-manager
  values:
  # replace below overrides to point to your override file.
  - overrides.yaml

```


 provides local overrides.yaml 
When integrate with ArgoCD, we can use helmfile template
When integrated with ArgoCD, we could use helmfile template command to generate all the manifest files, then check into a Git repo. ArgoCD is set up to monitor the changes in that Git repo and takes actions. From the Git repo we can review the exact changes in Kubernetes manifest files, and decide whether approve or reject the changes, before ArgoCD syncs and applies the changes. ArgoCD in this case is only reponsible to sync the target cluster to the desired state defined in the Git repo. 



