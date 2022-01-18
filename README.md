# Update
I found the issue for my problems, it was that I was using the seperate resource for function app settings. If i declared the environment settings inside the function app and in the staging slot, all worked, no validation error.

Note that you MIGHT need to initially remove the existing function app if you've deployed something before, after that I was able to deploy multiple times.

# Azure Function App with Deployment Slots 
A test to get Azure Function App using deployment slot for staging.

Currently there is a warning that storage is not configured correctly after the `deployment\functionapp.bicep` has been run.

I've tested the following:

1. Deploy the template, this will create function app with a deployment slot staging along with some support resources (service plan+insights)
2. Publish from VS Code the example function to the `staging`slot.
3. Perform a swap using the Azure CLI or through the portal.
4. Update the example function code to return a new version in the `Company.Function.HttpTrigger1.cs` class.
5. Publish the new code to the staging slot.
6. Verify that the productino api and the staging api return a (different) version.
7. Perform another swap, notice that everything is changed correctly.
8. Notice that there still is a warning regarding the storage configuration for the function app, which is said to impact scaling.
 
