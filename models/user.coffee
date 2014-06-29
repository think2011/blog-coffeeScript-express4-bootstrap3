mongodb = require './db'

class User
  constructor: (user) ->
    {@name, @password, @email, @avatar} = user

  ### 读取 ###
  @get: (name, callback) ->
    mongodb.open (err, db) ->
      if err
        callback err

      db.collection 'users', (err, collection) ->
        if err
          mongodb.close()
          return callback err

        collection.findOne(
          name: name
        , (err, user) ->
          mongodb.close()
          if err
            return callback err

          callback null, user
        )

  ### 保存 ###
  save: (callback) ->
    # 生成保存文档
    user =
      name    : @name
      email   : @email
      avatar  : @avatar
      password: @password

    # 打开数据库
    mongodb.open (err, db) ->
      if err
        return callback err

      # 读取 users 集合
      db.collection 'users', (err, collection) ->
        if err
          mongodb.close()
          return callback err

        collection.insert(
          user
        , safe: true
        , (err, user) ->
            mongodb.close()
            if err
              return callback err

            # 成功，返回用户文档
            callback null, user[0]
          )

module.exports = User