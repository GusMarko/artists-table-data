FROM public.ecr.aws/lambda/python:3.9

ARG APP_PATH=lambda_handler.py
ARG REQ_PATH=requirements.txt
COPY ${APP_PATH} ${LAMBDA_TASK_ROOT} 
COPY ${REQ_PATH} ${LAMBDA_TASK_ROOT}
WORKDIR ${LAMBDA_TASK_ROOT}
RUN pip install -r requirements.txt
CMD [ "lambda_handler.lambda_handler" ]