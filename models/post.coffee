settings = require '../settings'
mongodb  = require('mongodb').Db
markdown   = require('markdown').markdown

class Post
  constructor: (post) ->
    {@name, @title, @post, @tags, @avatar} = post


  ### 读取 ###
  @getOne: (name, day, title, callback) ->
    mongodb.connect settings.url, (err, db) ->
      if err
        callback err

      db.collection 'posts', (err, collection) ->
        if err
          db.close()
          return callback err

          # 根据用户名，日期，标题修改文章


        # 根据用户名，日期，标题查询文章
        collection.findOne
          name : name
          title: title
          time : +day # 被坑了，这货需要转换为数值型
        , (err, doc) ->
          if err
            db.close()
            return callback err

          if doc
            collection.update
              name : name
              title: title
              time : +day # 被坑了，这货需要转换为数值型
            , $inc :
                pv: 1
            , (err) ->
              db.close()
              if err
                return callback err

          doc.post = markdown.toHTML(doc.post)
          for i in doc.comments
            do ->
              i.content = markdown.toHTML(i.content)

          # 对评论按时间排序
          doc.comments.sort (v) ->
            return v.time

          callback null, doc



  ### 读取存档 ###
  @getArchive: (callback) ->
    mongodb.connect settings.url, (err, db) ->
      if err
        callback err

      db.collection 'posts', (err, collection) ->
        if err
          db.close()
          return callback err

        # 返回值包含 name、time、title 属性的文档
        collection.find({},
          name : 1
          title: 1
          time : 1
        ).sort(time: -1).toArray (err, doc) ->
          db.close()
          if err
            return callback err

          callback null, doc



  ### 读取标签 ###
  @getTags: (callback) ->
    mongodb.connect settings.url, (err, db) ->
      if err
        callback err

      db.collection 'posts', (err, collection) ->
        if err
          db.close()
          return callback err

        # 找出key的所有不同值
        collection.distinct 'tags', (err, docs) ->
          db.close()

          if err
            return callback err

          callback null, docs



  ### 读取具体标签 ###
  @getTag: (tag, callback) ->
    mongodb.connect settings.url, (err, db) ->
      if err
        callback err

      db.collection 'posts', (err, collection) ->
        if err
          db.close()
          return callback err

        collection.find(
          tags: (new RegExp tag)
        ,
          name: 1
          title: 1
          time: 1
        ).sort(time: -1).toArray (err, docs) ->
          db.close()
          if err
            return callback err

          callback null, docs



  ### 编辑 ###
  @edit: (name, day, title, callback) ->

    mongodb.connect settings.url, (err, db) ->
      if err
        callback err

      db.collection 'posts', (err, collection) ->
        if err
          db.close()
          return callback err

        # 根据用户名，日期，标题查询文章
        collection.findOne
          name : name
          title: title
          time : +day # 被坑了，这货需要转换为数值型
        , (err, doc) ->
          db.close()
          if err
            return callback err

          callback null, doc


  ### 更新 ###
  @update: (name, day, title, post, tags, callback) ->
    mongodb.connect settings.url, (err, db) ->
      if err
        callback err

      db.collection 'posts', (err, collection) ->
        if err
          db.close()
          return callback err

        # 根据用户名，日期，标题修改文章
        collection.update
          name : name
          title: title
          time : +day # 被坑了，这货需要转换为数值型
        , $set :
          post: post
          tags: tags
        , (err) ->
          db.close()
          if err
            return callback err

          callback null



  ### 删除 ###
  @remove: (name, day, title, callback) ->
    mongodb.connect settings.url, (err, db) ->
      if err
        callback err

      db.collection 'posts', (err, collection) ->
        if err
          db.close()
          return callback err

        # 根据用户名，日期，标题修改文章
        collection.remove
          name : name
          title: title
          time : +day # 被坑了，这货需要转换为数值型
        , w: 1
        , (err) ->
          db.close()
          if err
            return callback err

          callback null


  ### 分页读取 ###
  @getPage: (name, page, callback) ->
    mongodb.connect settings.url, (err, db) ->
      if err
        callback err

      db.collection 'posts', (err, collection) ->
        if err
          db.close()
          return callback err

        query = {}
        if name
          query.name = name

        collection.count query, (err, total) ->
          collection.find(
            query,
            skip : (page - 1) * 6
            limit: 6
          )
          .sort(time: -1).toArray (err, docs) ->
            db.close()
            if err
              return callback err

            # 输出markdown
            for i in docs
              do (i) ->
                i.post = markdown.toHTML(i.post)

            callback null, docs, total



  ### 读取所有 ###
  @getAll: (name, callback) ->
    mongodb.connect settings.url, (err, db) ->
      if err
        callback err

      db.collection 'posts', (err, collection) ->
        if err
          db.close()
          return callback err

        query = {}
        if name
          query.name = name

        collection.find(query).sort(time: -1).toArray (err, docs) ->
          db.close()
          if err
            return callback err

          # 输出markdown
          for i in docs
            do (i) ->
              i.post = markdown.toHTML(i.post)

          callback null, docs




  ### 搜索 ###
  @search: (keyword, callback) ->
    mongodb.connect settings.url, (err, db) ->
      if err
        callback err

      db.collection 'posts', (err, collection) ->
        if err
          db.close()
          return callback err

        keyword = new RegExp keyword, 'i'
        collection.find(
          title: keyword
        ,
          name : 1
          time : 1
          title: 1
        ).sort(time: -1).toArray (err, docs) ->
          db.close()
          if err
            return callback err

          callback null, docs


  ### 保存 ###
  save: (callback) ->
    # 生成保存文档
    post =
      name    : @name
      title   : @title
      post    : @post
      avatar  : @avatar
      tags    : @tags
      comments: []
      pv      : 0
      time    : Date.now()

    # 打开数据库
    mongodb.connect settings.url, (err, db) ->
      if err
        return callback err

      # 读取 posts 集合
      db.collection 'posts', (err, collection) ->
        if err
          db.close()
          return callback err

        collection.insert(
          post
        , safe: true
        , (err, post) ->
          db.close()
          if err
            return callback err

          # 成功，返回用户文档
          callback null, post[0]
        )

module.exports = Post