let SessionLoad = 1
if &cp | set nocp | endif
let s:cpo_save=&cpo
set cpo&vim
nmap gx <Plug>NetrwBrowseX
nnoremap <silent> <Plug>NetrwBrowseX :call netrw#NetrwBrowseX(expand("<cWORD>"),0)
let &cpo=s:cpo_save
unlet s:cpo_save
set autoindent
set backspace=indent,eol,start
set expandtab
set fileencodings=utf-8,latin1
set formatoptions=tcql
set helplang=ja
set hlsearch
set ruler
set shiftwidth=2
set tabstop=2
set textwidth=78
let s:so_save = &so | let s:siso_save = &siso | set so=0 siso=0
let v:this_session=expand("<sfile>:p")
silent only
cd ~/ruote-web2
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
badd +30 lib/smartmail_spreadsheet.rb
badd +36 config/initializers/participants.rb
badd +10 public/defs/job_request.rb
badd +11 config/config.yml
badd +6 _labs/sample_process.rb
badd +276 lib/smartmail_operation.rb
badd +34 lib/smartmail_formater.rb
badd +38 lib/smartmail_composer.rb
badd +207 lib/smartmail_mailer.rb
badd +107 lib/smartmail_listener.rb
badd +80 lib/smartmail_participant.rb
badd +5 lib/smartmail_ruote.rb
badd +36 db/migrate/20080918012151_create_workitems.rb
badd +15 config/initializers/listeners.rb
badd +15 test.rb
badd +11 memo.txt
badd +1 vendor/plugins/ruote_plugin/lib_ruote/openwfe/extras/participants/ar_participants.rb
badd +1 app/models/mail_item.rb
badd +1 db/migrate/20090612172846_create_mail_items.rb
args lib/smartmail_spreadsheet.rb
edit vendor/plugins/ruote_plugin/lib_ruote/openwfe/extras/participants/ar_participants.rb
set splitbelow splitright
set nosplitbelow
set nosplitright
wincmd t
set winheight=1 winwidth=1
argglobal
setlocal noarabic
setlocal autoindent
setlocal autoread
setlocal nobinary
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal comments=:#
setlocal commentstring=#\ %s
setlocal complete=.,w,b,u,t,i
setlocal completefunc=
setlocal nocopyindent
setlocal nocursorcolumn
setlocal nocursorline
setlocal define=^\\s*#\\s*define
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'ruby'
setlocal filetype=ruby
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=0
setlocal foldmarker={{{,}}}
setlocal foldmethod=manual
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=croql
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=0
setlocal imsearch=0
setlocal include=^\\s*\\<\\(load\\|w*require\\)\\>
setlocal includeexpr=substitute(substitute(v:fname,'::','/','g'),'$','.rb','')
setlocal indentexpr=GetRubyIndent()
setlocal indentkeys=0{,0},0),0],!^F,o,O,e,=end,=elsif,=when,=ensure,=rescue,==begin,==end
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255
setlocal keymap=
setlocal keywordprg=ri
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
setlocal nrformats=octal,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=.,/usr/lib/ruby/site_ruby/1.8,/usr/lib64/ruby/site_ruby/1.8,/usr/lib64/ruby/site_ruby/1.8/x86_64-linux,/usr/lib/ruby/site_ruby,/usr/lib64/ruby/site_ruby,/usr/lib64/site_ruby/1.8,/usr/lib64/site_ruby/1.8/x86_64-linux,/usr/lib64/site_ruby,/usr/lib/ruby/1.8,/usr/lib64/ruby/1.8,/usr/lib64/ruby/1.8/x86_64-linux,,~/.gem/ruby/1.8/gems/columnize-0.3.0/lib,~/.gem/ruby/1.8/gems/gimite-google-spreadsheet-ruby-0.0.2/lib,~/.gem/ruby/1.8/gems/hpricot-0.8.1/lib,~/.gem/ruby/1.8/gems/linecache-0.43/lib,~/.gem/ruby/1.8/gems/ruby-debug-base-0.10.3/lib,~/.gem/ruby/1.8/gems/sqlite3-ruby-1.2.4/lib,~/.gem/ruby/1.8/gems/tlsmail-0.0.1/lib,~/.gem/ruby/1.8/gems/tmail-1.2.3.1/lib,/usr/lib64/ruby/gems/1.8/gems/actionmailer-2.3.2/lib,/usr/lib64/ruby/gems/1.8/gems/actionpack-2.3.2/lib,/usr/lib64/ruby/gems/1.8/gems/activerecord-2.3.2/lib,/usr/lib64/ruby/gems/1.8/gems/activeresource-2.3.2/lib,/usr/lib64/ruby/gems/1.8/gems/activesupport-2.3.2/lib,/usr/lib64/ruby/gems/1.8/gems/atom-tools-2.0.1/lib,/usr/lib64/ruby/gems/1.8/gems/builder-2.1.2/l
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=2
setlocal noshortname
setlocal nosmartindent
setlocal softtabstop=0
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=.rb
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'ruby'
setlocal syntax=ruby
endif
setlocal tabstop=2
setlocal tags=
setlocal textwidth=78
setlocal thesaurus=
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
silent! normal! zE
let s:l = 99 - ((15 * winheight(0) + 15) / 31)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
99
normal! 06l
tabnext 1
if exists('s:wipebuf')
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20 shortmess=filnxtToO
let s:sx = expand("<sfile>:p:r")."x.vim"
if file_readable(s:sx)
  exe "source " . s:sx
endif
let &so = s:so_save | let &siso = s:siso_save
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
