FROM public.ecr.aws/lambda/python:3.13

COPY pyproject.toml ${LAMBDA_TASK_ROOT}

RUN pip install .


COPY scripts/* ${LAMBDA_TASK_ROOT}

CMD ["download.handler"]