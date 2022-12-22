def get_nested_value(obj, key):
    keys = key.split("/")
    for k in keys:
        if k in obj:
            obj = obj[k]
        else:
            return None
    return obj
 
obj = {"a":{"b":{"c":"d"}}}
key = "a/b/c"
print(get_nested_value(obj, key))

obj = {"x":{"y":{"z":"a"}}}
key = "x/y/z"
print(get_nested_value(obj, key))
