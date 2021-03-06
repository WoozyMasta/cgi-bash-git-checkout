#!/bin/sh
project_dir="/home/administrator/www/cgi/test/"

##### Передаем заголовки
echo "Content-type: text/html"
echo ""

##### Переходим в рабочий каталог
cd "${project_dir}"

##### Сбор данных
branch_name="$(git symbolic-ref HEAD 2>/dev/null)" ||
branch_name="(ветка без имени)"
branch_name=${branch_name##refs/heads/}
commit_message="$(git log --format=%B -n1 | tr '\r\n' ' ')"
commit_hash="$(git rev-parse HEAD)"
commit_author="$(git log -n 1 | grep Author | sed -e 's/Author: //' -e 's/[<>]//g')"
commit_date="$(git log -n 1 | grep Date | sed -e 's/Date: //')"

##### Начало документа
cat << EOF
<!DOCTYPE html>
<html>
  <head>
    <title>Newbie git</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta charset="utf-8">
    <link href="//netdna.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" rel="stylesheet" media="screen">
  </head>
  <body>
  <style type="text/css">
    body { background-color: #eaf0f3; }
  </style>
  <div class="container">
    <div class="row">
      <div class="col-sm-8 col-sm-offset-2 text-center">
        <h3>web-based git repository management interface</h3>
      </div>
    </div>
EOF
if [ -n "$QUERY_STRING" ]; then
  echo "<div class=\"col-sm-8 col-sm-offset-2 text-center\">"
  echo "${QUERY_STRING}" | grep --quiet "branch\|commit"
  if [ $? = 1 ]; then
    echo "<div class=\"alert alert-danger\"><strong>Опаньки...</strong> А что за запрос? Я такого не ждал!</div>"
  else
    echo "${QUERY_STRING}" | grep --quiet "branch"
    if [ $? = 0 ]; then
      user_request=${QUERY_STRING#branch=}
      user_request=$(echo "${user_request}"| sed 's/\(\s\|;\|&\|{\||\|"\|%\|+\).*$//')
      echo "<div class=\"alert alert-info\">Применяем ветку <strong>$user_request</strong></div>"
    else
      user_request=${QUERY_STRING#commit=}
      user_request=$(echo "${user_request}"| sed 's/\(\s\|;\|&\|{\||\|"\|%\|+\).*$//')
      echo "<div class=\"alert alert-info\">Сменим комит на <strong>$user_request</strong></div>"
    fi
    git fetch
    modified_files="$(git ls-files -m)"
    if [ -n "$modified_files" ]; then
      echo "<div class=\"alert alert-warning\">Были найдены измененные файлы, <strong>состояние востановлено</strong></br><strong style=\"white-space: pre;\">$modified_files</strong></div>"
      git reset --hard > /dev/null
    fi
    untracked_files="$(git ls-files --others --exclude-standard)"
    if [ -n "$untracked_files" ]; then
      echo "<div class=\"alert alert-warning\">Были найдены неотслеживаемые файлы</br><strong style=\"white-space: pre;\">$untracked_files</strong></div>"
    fi
    git checkout "$user_request" > /dev/null
    if [ $? = 1 ]; then
      echo "<div class=\"alert alert-danger\"><strong>Опаньки...</strong> Видимо где-то ошибка.</div>"
    else
      echo "<div class=\"alert alert-success\">Переключено на <strong>$user_request</strong></div>"
    fi
  fi
cat << EOF

<a href="?" class="btn btn-success btn-lg" role="button">Назад к информации</a>
</div>
EOF
else
cat << EOF
    <div class="row">
      <div class="col-sm-6 col-sm-offset-3">
        <ul class="list-group">
          <li class="list-group-item list-group-item-info">Текущая ветка:
            <input class="form-control text-center" type="text" value="${branch_name}">
          </li>
          <li class="list-group-item list-group-item-success">Текущий коммит:
            <input class="form-control text-center" type="text" value="${commit_message}">
          </li>
          <li class="list-group-item list-group-item-success">Хеш коммита:
            <input class="form-control text-center" type="text" value="${commit_hash}">
          </li>
          <li class="list-group-item list-group-item-success">Автор коммита:
            <input class="form-control text-center" type="text" value="${commit_author}">
          </li>
          <li class="list-group-item list-group-item-success">Дата коммита:
            <input class="form-control text-center" type="text" value="${commit_date}">
          </li>
        </ul>
        <div class="panel-group" id="accordion">
          <div class="panel panel-default">
            <div class="panel-heading list-group-item-warning">
              <h4 class="panel-title">
                <a data-toggle="collapse" data-parent="#accordion" href="#collapse1">
                Сменить ветку</a>
              </h4>
            </div>
            <div id="collapse1" class="panel-collapse collapse">
              <form action="$1">
                <div class="panel-body">
                  <div class="input-group">
                    <input type="text" class="form-control" placeholder="Точное название ветки" name="branch">
                    <div class="input-group-btn">
                      <button class="btn btn-default" type="submit">
                        <i class="glyphicon glyphicon-ok"></i>
                      </button>
                    </div>
                  </div>
                </div>
              </form>
            </div>
          </div>
          <div class="panel panel-default">
            <div class="panel-heading">
              <h4 class="panel-title">
                <a data-toggle="collapse" data-parent="#accordion" href="#collapse2">
                Перейти на коммит</a>
              </h4>
            </div>
            <div id="collapse2" class="panel-collapse collapse">
              <form action="$1">
                <div class="panel-body">
                  <div class="input-group">
                    <input type="text" class="form-control" placeholder="Полный или сокращенный хеш" name="commit">
                    <div class="input-group-btn">
                      <button class="btn btn-default" type="submit">
                        <i class="glyphicon glyphicon-ok"></i>
                      </button>
                    </div>
                  </div>
                </div>
              </form>
            </div>
          </div>
        </div>
      </div>
EOF
fi
cat << EOF
    </div>
    <script type="text/javascript" src="//code.jquery.com/jquery.js"></script>
    <script type="text/javascript" src="//netdna.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>
  </div>
  </body>
</html>
EOF
exit 0
