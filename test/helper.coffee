# Remove `_id`, timestamps coming from MongoDB.
exports.genericise = genericise = (obj) ->
    blacklist = [ '_id', 'created' ]
    # Array.
    if obj instanceof Array
        return ( genericise(row) for row in obj )
    # Object.
    if typeof(obj) is 'object'
        # Remove the blacklisted keys.
        for blk in blacklist
            if obj[blk] then delete obj[blk]
        # Go inside.
        nu = {}
        ( nu[k] = genericise(v) for k, v of obj )
        return nu
    # Rest...
    obj