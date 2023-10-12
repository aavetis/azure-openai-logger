from langchain.chat_models import AzureChatOpenAI
from langchain.chat_models import ChatOpenAI
from langchain.schema import HumanMessage
from langchain.embeddings.openai import OpenAIEmbeddings
from langchain.callbacks.streaming_stdout import StreamingStdOutCallbackHandler

# add your APIM hostname as base url
BASE_URL = "https://openai-api-XXXXXXXX.azure-api.net"

# name of your chat model deployment in Azure OpenAI
CHAT_DEPLOYMENT = "my-az-openai-chat-deployment-name"

# name of your embedding model deployment in Azure OpenAI
EMBEDDING_DEPLOYMENT = "my-az-openai-ada-deployment-name"

# be sure to inject your Subscription key as API key, or set it as an env var:
# `export OPENAI_API_KEY=YOUR_KEY`


# chat message example
model = AzureChatOpenAI(
    openai_api_base=BASE_URL,
    openai_api_version="2023-07-01-preview",
    deployment_name=CHAT_DEPLOYMENT,
    openai_api_type="azure",
)

out = model([HumanMessage(content="What is 2+2? Answer in one word.")])
print(out)


# embedding example
embeddings = OpenAIEmbeddings(
    deployment=EMBEDDING_DEPLOYMENT,
    model="ada",
    openai_api_base=BASE_URL,
    openai_api_type="azure",
)
text = "This is a test query."
query_result = embeddings.embed_query(text)

print(query_result)
