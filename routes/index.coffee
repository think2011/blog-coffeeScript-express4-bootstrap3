fs         = require 'fs'
crypto     = require 'crypto'
moment     = require 'moment'
User       = require '../models/user'
Post       = require '../models/post'
Comment    = require '../models/comment'
formidable = require 'formidable'

moment.lang 'zh-cn'

# 检查未登录
checkNotLogin = (req, res, next) ->
  if !req.session.user
    req.flash 'error', '请登录'
    return res.redirect '/login'
  next()


# 检查已登录
checkLogin = (req, res, next) ->
  if req.session.user
    req.flash 'error', '您已登录'
    return res.redirect 'back'
  next()

settings = require '../settings'
mongodb  = require('mongodb').Db

module.exports = (app) ->
  # 首页
  app.get '/', (req, res) ->
    # 生成页数
    page = if req.query.p then +req.query.p else 1

    Post.getPage null, page, (err, posts, total) ->
      if err
        posts = []

      # 转换时间格式
      for v in posts
        do (v) ->
          v.date = moment(v.time).startOf().fromNow();

      res.render 'index',
        title: '首页'
        posts    : posts
        page     : page
        total    : total
        totalPage: Math.ceil (total / 6)
        isFirst  : (page - 1) is 0
        isLast   : ((page - 1) * 6 + posts.length) is total
        user     : req.session.user
        success  : req.flash('success').toString()
        error    : req.flash('error').toString()


  # 搜索文章
  app.get '/search', (req, res) ->
    Post.search req.query.keyword, (err, posts) ->
      if err
        req.flash 'error', err
        return res.redirect '/'

      # 聚合数据
      refactor = []
      for v in posts
        do (v) ->
          v.smallDate = moment(v.time).format 'YYYY MMMM';
          v.date      = moment(v.time).format 'Do dddd hh:mm:ss';
          temp        = refactor[v.smallDate] ? refactor[v.smallDate] = []
          temp.push v

      posts = []
      # 重组数据
      for k, v of refactor
        posts.push
          date: k
          list: v

      res.render 'archive',
        title    : "#{req.query.keyword} 的搜索结果"
        posts    : posts
        user     : req.session.user
        success  : req.flash('success').toString()
        error    : req.flash('error').toString()


  # 存档
  app.get '/archive', (req, res) ->
    Post.getArchive (err, posts) ->
      if err
        req.flash 'error', err
        return res.redirect '/'

      # 聚合数据
      refactor = []
      for v in posts
        do (v) ->
          v.smallDate = moment(v.time).format 'YYYY MMMM';
          v.date      = moment(v.time).format 'Do dddd hh:mm:ss';
          temp        = refactor[v.smallDate] ? refactor[v.smallDate] = []
          temp.push v

      posts = []
      # 重组数据
      for k, v of refactor
        posts.push
          date: k
          list: v

      res.render 'archive',
        title: '存档'
        posts    : posts
        user     : req.session.user
        success  : req.flash('success').toString()
        error    : req.flash('error').toString()


  # 所有标签
  app.get '/tags', (req, res) ->
    Post.getTags (err, posts) ->
      if err
        req.flash 'error', err
        return res.redirect '/'

      res.render 'tags',
        title: '标签'
        posts    : posts
        user     : req.session.user
        success  : req.flash('success').toString()
        error    : req.flash('error').toString()


  # 标签文章
  app.get '/tags/:tag', (req, res) ->
    Post.getTag req.params.tag, (err, posts) ->
      if err
        req.flash 'error', err
        return res.redirect '/'

      # 聚合数据
      refactor = []
      for v in posts
        do (v) ->
          v.smallDate = moment(v.time).format 'YYYY MMMM';
          v.date      = moment(v.time).format 'Do dddd hh:mm:ss';
          temp        = refactor[v.smallDate] ? refactor[v.smallDate] = []
          temp.push v

      posts = []
      # 重组数据
      for k, v of refactor
        posts.push
          date: k
          list: v

      res.render 'archive',
        title    : "标记为 #{req.params.tag} 的文章"
        posts    : posts
        user     : req.session.user
        success  : req.flash('success').toString()
        error    : req.flash('error').toString()

  # 注册
  app.get '/reg', checkLogin
  app.get '/reg', (req, res) ->
    res.render 'reg',
      title: '注册'
      user   : req.session.user
      success: req.flash('success').toString()
      error  : req.flash('error').toString()


  app.get '/reg', checkLogin
  app.post '/reg', (req, res) ->
    name        = req.body.name
    email       = req.body.email
    password    = req.body.password
    password_re = req.body.password_re

    # 密码重复验证
    if password isnt password_re
      req.flash 'error', '两次输入的密码不一致'
      return res.redirect '/reg'

    # 生成头像
    md5      = crypto.createHash 'md5'
    avatar   = md5.update(email.toLowerCase()).digest 'hex'

    # 加密密码
    md5      = crypto.createHash 'md5'
    password = md5.update(password).digest 'hex'

    newUser  = new User(
      name    : name
      email   : email
      avatar  : avatar
      password: password
    )

    User.get name, (err, user) ->
      if user
        req.flash 'error', '用户已存在'
        return res.redirect '/reg'

      newUser.save (err, user) ->
        if err
          req.flash 'error', err
          return res.redirect '/reg'

        # 注册成功
        req.session.user = user
        req.flash 'success', '注册成功'
        res.redirect '/'


  # 登录
  app.get '/login', checkLogin
  app.get '/login', (req, res) ->
    res.render 'login',
      title: '登录'
      user   : req.session.user
      success: req.flash('success').toString()
      error  : req.flash('error').toString()

  app.get '/login', checkLogin
  app.post '/login', (req, res) ->
    md5      = crypto.createHash 'md5'
    password = md5.update(req.body.password).digest 'hex'

    User.get req.body.name, (err, user) ->
      # 检查用户名
      if !user
        req.flash 'error', '用户名不存在'
        return res.redirect '/login'

      # 检查密码
      if user.password isnt password
        req.flash 'error', '密码错误'
        return res.redirect '/login'

      # 认证通过
      req.session.user = user
      req.flash 'success', '登录成功'
      res.redirect '/'


  # 上传
  app.get '/upload', checkNotLogin
  app.get '/upload', (req, res) ->
    res.render 'upload',
      title  : '上传'
      user   : req.session.user
      success: req.flash('success').toString()
      error  : req.flash('error').toString()

  app.post '/upload', checkNotLogin
  app.post '/upload', (req, res) ->
    uploadDir = './public/upload/'
    filesBox  = []
    form      = new formidable.IncomingForm()

    form.uploadDir = './temp' # 因为renameSync方法不能跨盘符

    form.parse req, (err, fields, files) ->
      for k, v of files
        if v.size > 0
          fs.renameSync v.path, uploadDir + v.name
          filesBox.push "<p>![](#{'/upload/' + v.name})</p>"

      req.flash 'success', "上传成功 #{filesBox.join('')}"
      res.redirect '/upload'


  # 发表
  app.get '/post', checkNotLogin
  app.get '/post', (req, res) ->
    res.render 'post',
      title  : '发表'
      user   : req.session.user
      success: req.flash('success').toString()
      error  : req.flash('error').toString()

  app.get '/post', checkNotLogin
  app.post '/post', (req, res) ->
    currentUser = req.session.user

    # 生成头像
    md5      = crypto.createHash 'md5'
    avatar   = md5.update(currentUser.email.toLowerCase()).digest 'hex'

    post = new Post(
      name  : currentUser.name
      avatar: avatar
      title : req.body.title
      post  : req.body.post
      tags  : req.body.tags
    )

    post.save (err) ->
      if err
        req.flash 'error', err
        return res.redirect '/post'

      # 发布成功
      req.flash 'success', '发布成功'
      res.redirect '/'


  # 用户文章
  app.get '/u/:name', (req, res) ->
    User.get req.params.name, (err, user) ->
      if !user
        req.flash 'error', '用户不存在'
        return res.redirect '/'

      # 生成页数
      page = if req.query.p then +req.query.p else 1

      Post.getPage user.name, page, (err, posts, total) ->
        if err
          req.flash 'error', err
          return res.redirect '/'

        # 转换时间格式
        for v in posts
          do (v) ->
            v.date = moment(v.time).startOf().fromNow();

        res.render 'user',
          title: "#{user.name}的文章"
          posts    : posts
          page     : page
          totalPage: Math.ceil (total / 10)
          isFirst  : (page - 1) is 0
          isLast   : ((page - 1) * 10 + posts.length) is total
          user     : req.session.user
          success  : req.flash('success').toString()
          error    : req.flash('error').toString()


  # 具体文章
  app.get '/u/:name/:day/:title', (req, res) ->
    params = req.params

    Post.getOne params.name, params.day, params.title, (err, post) ->
      if err
        req.flash 'error', err
        return res.redirect '/'

      # 转换时间格式
      post.date = moment(post.time).startOf().fromNow();
      for i in post.comments
        do ->
          i.date = moment(i.time).startOf().fromNow();

      res.render 'article',
        title  : params.title
        user   : req.session.user
        post   : post
        success: req.flash('success').toString()
        error  : req.flash('error').toString()


  # 保存评论
  app.post '/u/:name/:day/:title', (req, res) ->
    params  = req.params
    comment =
      name   : req.body.name || '陌生人'
      content: req.body.content
      time   : Date.now()

    newComment = new Comment
      name   : params.name
      title  : params.title
      time   : params.day
      comment: comment

    newComment.save (err) ->
      if err
        req.flash 'error', err
        return res.redirect 'back'

      req.flash 'success', '评论成功'
      return res.redirect 'back'


  # 编辑文章
  app.get '/edit/:name/:day/:title', checkNotLogin
  app.get '/edit/:name/:day/:title', (req, res) ->
    params = req.params

    Post.edit params.name, params.day, params.title, (err, post) ->
      if err
        req.flash 'error', err
        return res.redirect 'back'

      res.render 'edit',
        title  : "编辑 #{params.title}"
        user   : req.session.user
        post   : post
        success: req.flash('success').toString()
        error  : req.flash('error').toString()

  app.post '/edit/:name/:day/:title', checkNotLogin
  app.post '/edit/:name/:day/:title', (req, res) ->
    params      = req.params
    currentUser = req.session.user

    Post.update currentUser.name, params.day, params.title, req.body.post, req.body.tags, (err, post) ->
      url = "/u/#{currentUser.name}/#{params.day}/#{params.title}"
      if err
        req.flash 'error', err
        return res.redirect url

      req.flash 'success', '编辑成功'
      return res.redirect url


  # 删除文章
  app.get '/remove/:name/:day/:title', checkNotLogin
  app.get '/remove/:name/:day/:title', (req, res) ->
    params      = req.params
    currentUser = req.session.user

    Post.remove currentUser.name, params.day, params.title, (err, post) ->
      if err
        req.flash 'error', err
        return res.redirect 'back'

      req.flash 'success', '删除成功'
      return res.redirect '/'


  # 注销
  app.get '/logout', checkNotLogin
  app.get '/logout', (req, res) ->
    req.session.user = null
    req.flash 'success', '注销成功'
    res.redirect '/'