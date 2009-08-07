
# create process
li = parse_launchitem
options = { :variables => { 'launcher' => current_user.login } }
fei = ruote_engine.launch(li, options)

