# RTI HTTP Source App

This folder contains the HTTP event generator used by the Real-Time Intelligence lab.

Fabric Eventstream uses the **HTTP** source connector to poll a public HTTP endpoint. The Azure Function in this folder provides that endpoint and returns generated service events as JSON.

## Recommended Workshop Path

1. Deploy the Azure Function HTTP generator in [azure-function-http-bridge/](azure-function-http-bridge/).
2. Get the Function URL and key.
3. In Fabric Eventstream, select **Add source** > **HTTP**.
4. Configure Fabric to call the Function endpoint with method `GET`.
5. Route the HTTP source to Eventhouse/KQL.

## Function Endpoint

```text
GET https://<function-app-name>.azurewebsites.net/api/events?code=<function-key>&batchSize=25
```

The response is a JSON array of generated service events.

## Fabric HTTP Source Settings

| Setting | Value |
| --- | --- |
| URL | `https://<function-app-name>.azurewebsites.net/api/events` |
| Authentication kind | API Key |
| API key | `<function-key>` |
| Request method | GET |
| Request interval (s) | `5` |
| Query parameter | `code=${apiKey}` |
| Query parameter | `batchSize=25` |

## Files

- [azure-function-http-bridge/function_app.py](azure-function-http-bridge/function_app.py)
- [azure-function-http-bridge/README.md](azure-function-http-bridge/README.md)
- [azure-function-http-bridge.zip](azure-function-http-bridge.zip)

## Reconciliation

The generated events use keys that match the workshop lakehouse dimensions and request pattern:

- `RequestId` -> `FactServiceRequest.RequestId`
- `ServiceId` -> `DimService.ServiceId`
- `AgencyId` -> `DimAgency.AgencyId`
- `ChannelId` -> `DimChannel.ChannelId`

## Microsoft Learn References

- https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/add-source-http
- https://learn.microsoft.com/azure/azure-functions/functions-create-function-app-portal
- https://learn.microsoft.com/azure/azure-functions/deployment-zip-push
