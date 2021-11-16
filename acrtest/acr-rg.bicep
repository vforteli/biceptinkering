param AcrName string

resource acr 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
    name: AcrName
    location: resourceGroup().location
    sku: {
        name: 'Standard'
    }
    identity: {
        type: 'SystemAssigned'
    }
    properties: {
        adminUserEnabled: false
    }
}

/*
 {
            "copy": {
                "count": "[length(parameters('ImageNames'))]",
                "name": "cleanuptasks"
            },
            "type": "Microsoft.ContainerRegistry/registries/tasks",
            "apiVersion": "2019-06-01-preview",
            "name": "[concat(parameters('AcrName'), '/', variables('acrPurgeTaskName'), '-', parameters('ImageNames')[copyIndex()])]",
            "location": "[resourceGroup().location]",
            "dependsOn": [
                "[resourceId('Microsoft.ContainerRegistry/registries', parameters('AcrName'))]"
            ],
            "properties": {
                "agentConfiguration": {
                    "cpu": 2
                },
                "status": "Enabled",
                "platform": {
                    "os": "linux",
                    "architecture": "amd64"
                },
                "step": {
                    "type": "EncodedTask",
                    "encodedTaskContent": "dmVyc2lvbjogdjEuMS4wDQpzdGVwczogDQogIC0gY21kOiBhY3IgcHVyZ2UgLS1maWx0ZXIgInt7LlZhbHVlcy5pbWFnZW5hbWV9fTouKiIgLS1hZ28gMGQgLS11bnRhZ2dlZCAtLWtlZXAgMCAtLWRyeS1ydW4NCiAgICBkaXNhYmxlV29ya2luZ0RpcmVjdG9yeU92ZXJyaWRlOiB0cnVlDQogICAgdGltZW91dDogMzYwMA==",
                    "values": [
                        {
                            "name": "imagename",
                            "value": "[parameters('ImageNames')[copyIndex()]]"
                        }
                    ]
                },
                "timeout": 3600,
                "trigger": {
                    "timerTriggers": [
                        {
                            "name": "t1",
                            "schedule": "0 0 * * *",
                            "status": "Enabled"
                        }
                    ],
                    "baseImageTrigger": {
                        "baseImageTriggerType": "Runtime",
                        "status": "Enabled",
                        "name": "defaultBaseimageTriggerName"
                    }
                }
            }
 
*/
