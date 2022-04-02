API URL = https://bestapiever01.azurewebsites.net/weatherforecast 

Preview Slot URL = https://bestapiever01-preview.azurewebsites.net/weatherforecast


**My Approach and Solution Selection**

I approached this challenge as though I was implementing a production system, though I had to keep in mind the time constraints of the challenge. Even though I am more familiar with Azure DevOps to make things more interesting I chose to use GitHub Actions for the deployments.

My thoughts were to use a managed PAAS solution that is well supported, easy to implement, provides high availability, scalable, with the ability to perform health checks and built-in monitoring. Basically the platform should be able to do it all without strapping on additional components.

In my opinion IAAS should be a last resort, IAAS has high admin overheads and automation is more complex. IAAS makes no sense here.

AKS would normally be my choice of platform here though running a single container in a AKS cluster makes zero sense and is way overkill for the task.

ACI would also be a good fit for the challenge. It is a simplistic solution where we can utilise the liveness and readiness probes to ensure the health and readiness of the service.

I decided to keep things interesting and go with Azure Web Apps for Containers, Azure Web Apps for Containers has built in health checks, the ability to use deployment slots to ensure a healthy service prior to promoting to production, on paper it made sense. My downfall here was I made an assumption that the Web App for Containers functionality was as mature as that with deploying a traditional web apps.

I had two major issues, firstly I was unsuccessful in passing the APIKEY ENV Var into the container (in a secure way). Azure documentation says that the APP setting is passed into the process as environmental variables automatically, this was correct I could see and access the host variable on the via the Kudu console.
As I needed to pass the APIKEY into the container as a ENV var without modifying the container, I tried using the Web Apps Stack Settings start-up command which basically will append the docker run command the web apps uses to launch the container. Passing just "-e APIKEY" should work. When passing the -e APIKEY will allow docker to access the host variable. Unfortunately, this didn’t work and due to time constraints, I didn’t have much time to perform more troubleshooting and hacked it by passing "-e APIKEY=1997-07-16 00:00:00" which works, and the health endpoint returned "healthy".

The second issue I had was, I had planned to use the Auto Swap Slot functionality of the Web App, with the idea that I configured the health check to use the health check endpoint of the API knowing that the swap will only occur once the slot is reporting a healthy health check. Too easy I thought!! Well Web App for containers (Linux Containers) does not support Auto Swap function therefore my slots require either a manual swap or I will need to add an AZ CLi task in my GitHub deployment pipeline to perform the task maybe with a custom health check prior. (Very disappointing!) GitHub Actions doesn’t currently have a swap slot action, where Azure DevOps can easily perform this task.

**Deployments**

With the deployments as mentioned previously I used GitHub actions which sometimes for deployments I describe as "Azure DevOps yaml pipelines with one hand tied behind your back."

The Infrastructure and the API have two different lifecycles therefore I created two deployment workflows (or pipelines) to cater for each lifecycle. 

First one was to deploy the infrastructure, the infrastructure was coded up as Terraform config and deployed with the "Infra" workflow. The workflow abstracts all the complexity by calling two custom composite actions "Terraform Plan" and "Terraform Apply". (I did have plans to include outputting the TF Plan to the PR though ran out of time and scrapped it).

The TF Config deploys the following:

Resource Group

Key Vault

Key Vault Access Policies 

Key Vault Secret

App Plan

Web App & Slot

The Web App deployment also deploys the API container image though as I mentioned, going forward the API deployments should be managed via a different workflow (Life Cycle reasons). I used the TF "Lifecycle Ignore changes" on the docker image tag so that future deployments of the "Infra" workflow will not revert the API version.

The "besteverapi" Action is a simple workflow for deploying new versions of the API. The workflow consists of logging into Azure and deploying the image to the web apps preview slot which will need to be health checked and swapped as previously mentioned.

**Final Thoughts**

Overall, I am a little disappointed though I tried to have a little fun with this by using a PAAS solution I have little experience with and it came back to bite me. I would be very interested to know if others have chosen the same path of using Azure Web Apps and was able to successfully get the APIKEY passed in securely?
If I had my time again, I think I would have gone down the ACI route.
I appreciate the opportunity to do this challenge and did have fun while learning plenty along the way. I loo forward to discussing this in more detail.
