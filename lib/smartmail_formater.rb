
require 'rubygems'
require 'kconv'
require 'lib/smartmail_operation'

class SMFormater

  @@field_separator = '   '
  @@selection_menu_name = '選択項目'
  @@underline = [0x1B].pack("c*") + "[1;4;36m"
  @@normal = [0x1B].pack("c*") + "[0m\n"

  @@maps = {
      'MAIL_TITLE' => 'メールタイトル',
      'MAIL_BODY' => 'メール内容',
      'REMINDER' => "再通知",
      'SELECTION_MENU' => '選択メニュー'
  }

  @@opts = {
    'SELECTION' => 'ステップ説明',
    'MAIL' => 'ステップ略称',
    'TITLE' => 'メールタイトル',
    'CONTENTS' => '選択メニューの自動返信内容'
  }

  def self.get_email_maps
    @@maps
  end

  def self.get_reply_options
    @@opts
  end

  def self.format( email_contents, format )
    email = Hash.new
    contents = change_to_email_contents( email_contents, format )
    email[:title] = format_title( contents, format )
    email[:body] = {
      :plain => format_contents( contents, 'plain' ),
      :html => format_contents( contents, 'html' )
    }
    email
  end

  protected

  def self.change_to_email_contents( contents, format )
    email_contents = Hash.new
    @@maps.each_pair do |replace, field|
      email_contents[ replace ] = contents[ field ]
    end
    # email_contents.each { |it| puts "change_to_email_contents2: #{it}" }
    email_contents
  end

  def self.format_title( email_contents, format )
    title = email_contents['MAIL_TITLE']
    # puts "format_title: #{title.inspect}"
    return title if title.is_a? String
    pre = title['pre_contents']
    rep = title['replace_contents'].first
    return pre.gsub( rep.keys.first ) { rep.values.first }
  end

  def self.css_insertion()
"""
<style type=\"text/css\" media=\"screen\">
	
	/* common
	--------------------------------------------------*/
	
	body {
		margin: 0px;
		padding: 0px;
		color: #fff;
		background: #930;
	}
	#BodyImposter {
		color: #fff;
		background: #930 url(\"http://www.email-standards.org/acid/img/bgBody.gif\") repeat-x;
		background-color: #930;
		font-family: Arial, Helvetica, sans-serif;
		width: 100%;
		margin: 0px;
		padding: 0px;
		text-align: center;
	}
	#BodyImposter dt {
		font-size: 14px;
		line-height: 1.5em;
		font-weight: bold;
	}
	#BodyImposter dd,
	#BodyImposter li,
	#BodyImposter p,
	#WidthHeight span {
		font-size: 12px;
		line-height: 1.5em;
	}
	#BodyImposter dd,
	#BodyImposter dt {
		margin: 0px;
		padding: 0px;
	}
	#BodyImposter dl,
	#BodyImposter ol,
	#BodyImposter p,
	#BodyImposter ul {
		margin: 0px 0px 4px 0px;
		padding: 10px;
		color: #fff;
		background: #ad5c33;
	}
	#BodyImposter small {
		font-size: 11px;
		font-style: italic;
	}
	#BodyImposter ol li {
		margin: 0px 0px 0px 20px;
		padding: 0px;
	}
	#BodyImposter ul#BulletBg li {
		background: url(\"http://www.email-standards.org/acid/img/bullet.gif\") no-repeat 0em 0.2em;
		padding: 0px 0px 0px 20px;
		margin: 0px;
		list-style: none;
	}
	#BodyImposter ul#BulletListStyle li {
		margin: 0px 0px 0px 22px;
		padding: 0px;
		list-style: url(\"http://www.email-standards.org/acid/img/bullet.gif\");
	}
	
	/* links
	--------------------------------------------------*/
	
	#BodyImposter a {
		text-decoration: underline;
	}
	#BodyImposter a:link,
	#BodyImposter a:visited {
		color: #dfb8a4;
		background: #ad5c33;
	}
	#ButtonBorders a:link,
	#ButtonBorders a:visited {
		color: #fff;
		background: #892e00;
	}
	#BodyImposter a:hover {
		text-decoration: none;
	}
	#BodyImposter a:active {
		color: #000;
		background: #ad5c33;
		text-decoration: none;
	}
	
	/* heads
	--------------------------------------------------*/
	
	#BodyImposter h1,
	#BodyImposter h2,
	#BodyImposter h3 {
		color: #fff;
		background: #ad5c33;
		font-weight: bold;
		line-height: 1em;
		margin: 0px 0px 4px 0px;
		padding: 10px;
	}
	#BodyImposter h1 {
		font-size: 34px;
	}
	#BodyImposter h2 {
		font-size: 22px;
	}
	#BodyImposter h3 {
		font-size: 16px;
	}
	#BodyImposter h1:hover,
	#BodyImposter h2:hover,
	#BodyImposter h3:hover,
	#BodyImposter dl:hover,
	#BodyImposter ol:hover,
	#BodyImposter p:hover,
	#BodyImposter ul:hover {
		color: #fff;
		background: #892e00;
	}
	
	/* boxes
	--------------------------------------------------*/
	
	#Box {
		width: 470px;
		margin: 0px auto;
		padding: 40px 20px;
		text-align: left;
	}
	p#ButtonBorders {
		clear: both;
		color: #fff;
		background: #892e00;
		border-top: 10px solid #ad5c33;
		border-right: 1px dotted #ad5c33;
		border-bottom: 1px dashed #ad5c33;
		border-left: 1px dotted #ad5c33;
	}
	p#ButtonBorders a#Arrow {
		padding-right: 20px;
		background: url(\"http://www.email-standards.org/acid/img/arrow.gif\") no-repeat right 2px;
	}
	p#ButtonBorders a {
		color: #fff;
		background-color: #892e00;
	}
	p#ButtonBorders a#Arrow:hover {
		background-position: right -38px;
	}
	#Floater {
		width: 470px;
	}
	#Floater #Left {
		float: left;
		width: 279px;
		height: 280px;
		color: #fff;
		background: #892e00;
		margin-bottom: 4px;
	}
	#Floater #Right {
		float: right;
		width: 187px;
		height: 280px;
		color: #fff;
		background: #892e00 url(\"http://www.email-standards.org/acid/img/ornament.gif\") no-repeat right 
bottom;
		margin-bottom: 4px;
	}
	#Floater #Right p {
		color: #fff;
		background: transparent;
	}
	#FontInheritance {
		font-family: Georgia, Times, serif;
	}
	#MarginPaddingOut {
		padding: 20px;
	}
	#MarginPaddingOut #MarginPaddingIn {
		padding: 15px;
		color: #fff;
		background: #ad5c33;
	}
	#MarginPaddingOut #MarginPaddingIn img {
		background: url(\"http://www.email-standards.org/acid/img/bgPhoto.gif\") no-repeat;
		padding: 15px;
	}
	span#SerifFont {
		font-family: Georgia, Times, serif;
	}
	p#QuotedFontFamily {
		font-family: \"Trebuchet MS\", serif;
	}
	#WidthHeight {
		width: 470px;
		height: 200px;
		color: #fff;
		background: #892e00;
	}
	#WidthHeight span {
		display: block;
		padding: 10px;
	}
	
</style>
    """
  end

  def self.html_format()
    html_body = """
    <!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN'>
     <html lang='ja'>
     <head>
       <meta http-equiv='Content-Language' content='ja'>
       <meta http-equiv='Content-Type' content='text/html; charset=iso-2022-jp'>
       <title></title>
     </head>
         <body bgcolor='#ffffff' style='margin:0; padding:0'>
           --------------<br>
           MAIL_TITLE<br>
           --------------<br>
           MAIL_BODY<br>
           <br>
           REMINDER<br>
           <br>
           <div bgcolor='#ccffcc' width='100%'>
           =============<br>
    #{@@selection_menu_name}<br>
           =============<br>
           SELECTION_MENU<br>
           </div>
         </body>
     </html>
    """
    html_body
  end

  def self.html_options
    "<div><a href=\"mailto:MAIL?subject=TITLE&amp;body=CONTENTS\">SELECTION</a></div>\n"
  end

  def self.plain_format()
    plain_body = """
--------------
MAIL_TITLE 
--------------

MAIL_BODY 

REMINDER 

==============
    #{@@selection_menu_name}
==============

SELECTION_MENU 
~~~~~~~~~~~~~~
"""
    plain_body
  end

  def self.plain_options
    options = """
SELECTION:
MAIL
"""
    options
  end

  def self.format_contents( contents, format )
    result = '  '
    case format
    when 'plain'
      original = plain_format
    when 'html'
      original = html_format
    end
    original = original.gsub(/\r\n|\r|\n/,'[NEW_LINE]')
    contents.each_pair do |replace,value|
      # p "format_contents1: pre:#{replace} --> to:#{value}"
      next unless value
      pre_contents = value['pre_contents'] || value
      pre_contents = pre_contents.gsub(/\r\n|\r|\n/, "<br>\r\n") if format == 'html'
      to_contents = value['replace_contents'] || Array.new
      to_contents.each do |replace_item|
        replace_str = replace_item.keys.first
        replace_to_contents = replace_item.values.first || ''
        is_options = /\{sm_ref:((\w+,?)*)\}/ =~ replace_str
        # p "format_contents1.2: rep? #{replace_str} --> #{replace_to_contents} option? #{is_options}"
        if is_options
          replace_to_contents = format_options( replace_to_contents, format )
        else
          replace_to_contents = replace_to_contents.gsub(/\r\n|\r|\n/, "<br>\r\n") if format == 'html'
        end
        # p "format_contents2: pre:#{pre_contents} , rep:#{replace_str}, to:#{replace_to_contents}"
        pre_contents = pre_contents.gsub( replace_str ) { replace_to_contents }
        # p "format_contents3: pre:#{pre_contents}"
      end
      original = original.gsub( replace ) { pre_contents }
    end
    original = original.gsub('[NEW_LINE]',"\n")
    result = original
    # print "#{@@underline}send email::#{@@normal}", result, "\n" if format == 'html'
    result
  end

  def self.format_options( options_menu, format )
    result = ''
    case format
    when 'plain'
      original = plain_options
    when 'html'
      original = html_options
    end
    result = ''
    # puts "#{@@underline}#{options_menu}#{@@normal}"
    options_menu.each_pair do |option,contents|
      _original = original.gsub(/\r\n|\r|\n/,'[NEW_LINE]')
      @@opts.each_pair do |replace,field|
        _value = contents[field] || ''
        # puts "#{@@underline}replace:#{replace} --> to:#{_value}#{@@normal}"
        _value = _value.gsub(/\r\n|\r|\n/,'%0D%0A')
        _original.gsub!( replace ) { _value }
        # puts "#{@@underline}#{option}:#{_original}#{@@normal}"
      end
      _original = _original.gsub('[NEW_LINE]',"\r\n")
      # puts "add to menu: #{@@underline}#{option} ==> #{_original}#{@@normal}"
      result += _original
    end
    # puts "#{@@underline}result:#{result}#{@@normal}"
    result.to_s
  end

end
