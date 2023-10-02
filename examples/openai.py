import os
import openai

openai.api_type = "azure"
openai.api_key = os.getenv("OPENAI_API_KEY")
openai.api_base = "https://openai-api-XXXXXX.azure-api.net"
openai.api_version = "2023-07-01-preview"
openai.api_key = os.getenv("OPENAI_API_KEY")

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
