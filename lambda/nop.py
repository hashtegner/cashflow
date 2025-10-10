def handler(event, _context):
    """
    This is a no-op lambda function. It's used as default lambda function for the docker image.
    """

    return {
        "received_event": event,
        "message": "Hello, World!",
    }


if __name__ == "__main__":
    handler({"hello": "world"}, {})
