# Azure Function HTTP Event Generator

This Function generates synthetic citizen service events over HTTP. Microsoft Fabric Eventstream uses the **HTTP** source connector to poll this endpoint and ingest the JSON response.

This path uses:

- Azure Function App for the public HTTP endpoint
- Fabric Eventstream **HTTP** source
- Eventhouse/KQL destination

It does not use Azure Event Hubs, Event Hubs output binding, or Fabric Custom App source.

## Endpoint

The Function exposes:

```text
GET /api/events?code=<function-key>&batchSize=25
```

It returns a JSON array of generated service events. The generated keys match the workshop dimensions and request ID pattern.

## Step 1: Create Function App In Azure Portal

1. Open https://portal.azure.com.
2. Select **Create a resource**.
3. Search for **Function App**.
4. Select **Function App**.
5. Select **Create**.
6. For **Hosting option**, choose **Consumption** unless your instructor specifies another option.
7. On the **Basics** page, use these values:

| Setting | Value |
| --- | --- |
| Subscription | Your workshop Azure subscription |
| Resource group | Create new, for example `rg-fabric-rti-workshop` |
| Function App name | Globally unique name, for example `func-fabric-rti-<your-initials>` |
| Runtime stack | Python |
| Version | Available Python version in the portal |
| Region | Region close to the workshop region |
| Operating system | Linux, if prompted |

8. Keep the default values for Storage and Monitoring unless your instructor provides specific values.
9. Select **Review + create**.
10. Select **Create**.
11. Wait for deployment to finish.
12. Select **Go to resource**.

## Step 2: Add Application Setting

1. In the Function App, go to **Settings** > **Environment variables** or **Configuration**.
2. Add this application setting:

| Setting | Value |
| --- | --- |
| `DEFAULT_BATCH_SIZE` | `25` |

3. Save the setting.
4. Wait for the Function App to restart.

## Step 3: Deploy The Function Code With Azure Cloud Shell

1. In Azure portal, select the **Cloud Shell** icon in the top toolbar.
2. Choose **Bash**.
3. If Cloud Shell asks to create storage, follow the prompt to create it.
4. Upload `../azure-function-http-bridge.zip` into Cloud Shell.
5. In Cloud Shell, set these variables:

```bash
RESOURCE_GROUP="rg-fabric-rti-workshop"
FUNCTION_APP="<your-function-app-name>"
ZIP_FILE="azure-function-http-bridge.zip"
```

6. Deploy the zip file:

```bash
az functionapp deployment source config-zip \
  --resource-group "$RESOURCE_GROUP" \
  --name "$FUNCTION_APP" \
  --src "$ZIP_FILE" \
  --build-remote true
```

## Step 4: Get The Function URL And Key

1. In Azure portal, open the Function App.
2. Select **Functions**.
3. Select `HttpToFabricEventstream`.
4. Select **Get function URL**.
5. Copy the default function URL.

The URL should look similar to:

```text
https://<function-app-name>.azurewebsites.net/api/events?code=<function-key>
```

For Fabric HTTP source, use:

| Fabric HTTP setting | Value |
| --- | --- |
| URL | `https://<function-app-name>.azurewebsites.net/api/events` |
| Authentication kind | API Key |
| API key | `<function-key>` |
| Query parameter | `code=${apiKey}` |
| Query parameter | `batchSize=25` |
| Request method | GET |

## Step 5: Validate In Browser

Open this URL in a browser:

```text
https://<function-app-name>.azurewebsites.net/api/events?code=<function-key>&batchSize=5
```

You should see a JSON array of generated service events.

## Microsoft Learn References

- https://learn.microsoft.com/azure/azure-functions/functions-create-function-app-portal
- https://learn.microsoft.com/azure/azure-functions/deployment-zip-push
- https://learn.microsoft.com/azure/azure-functions/functions-how-to-use-azure-function-app-settings
- https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/add-source-http
