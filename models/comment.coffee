settings = require '../settings'
mongodb  = require('mongodb').Db

class Comment
  constructor: (comment) ->
    {@name, @title, @time, @comment} = comment


  ### 保存 ###
  save: (callback) ->
    post =
      name    : @name
      title   : @title
      time    : @time
      comment : @comment

    # 打开数据库
    mongodb.connect settings.url, (err, db) ->
      if err
        return callback err

      # 读取 Post 集合
      db.collection 'posts', (err, collection) ->
        if err
          db.close()
          return callback err

        collection.update
          name  : post.name
          title : post.title
          time  : +post.time # 被坑了，这货需要转换为数值型
        , $push : 'comments': post.comment
        , (err) ->
          db.close()
          if err
            return callback err

          callback null

module.exports = Comment