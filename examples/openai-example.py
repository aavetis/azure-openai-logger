import os
import openai


openai.api_type = "azure"

# be sure to inject your Subscription key as API key, or set it as an env var:
# `export OPENAI_API_KEY=YOUR_KEY`
openai.api_key = os.getenv("OPENAI_API_KEY")

# add your APIM hostname as base url
openai.api_base = "https://openai-api-XXXXXX.azure-api.net"

openai.api_version = "2023-07-01-preview"

# standard ChatCompletion example
response = openai.ChatCompletion.create(
    model="gpt-3.5-turbo",
    messages=[
        {
            "role": "system",
            "content": "You respond in emojis only.",
        },
        {
            "role": "user",
            "content": "how are you today?",
        },
    ],
)

print(response)
