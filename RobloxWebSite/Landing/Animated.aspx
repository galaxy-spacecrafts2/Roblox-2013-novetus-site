<%@ Page Language="C#" AutoEventWireup="true" %>
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <title>ROBLOX</title>
    <meta http-equiv="X-UA-Compatible" content="IE=edge,requiresActiveX=true">
    <meta name="author" content="ROBLOX Corporation">
    <meta name="description" content="User-generated MMO gaming site for kids, teens, and adults. Players architect their own worlds. Builders create free online games that simulate the real world. Create and play amazing 3D games. An online gaming cloud and distributed physics engine.">
    <meta name="keywords" content="free games, online games, building games, virtual worlds, free mmo, gaming cloud, physics engine">
    <meta name="robots" content="all">
    <link rel="icon" type="image/vnd.microsoft.icon" href="/favicon.ico">
    <link rel="stylesheet" type="text/css" href="/css/Navigation.css">

    <script type="text/javascript" src="/js/jquery/jquery-1.7.2.min.js"></script>
    <script type="text/javascript" src="/js/Microsoft/MicrosoftAjax.js"></script>

    <style type="text/css">
        body {
            background: url("https://web.archive.org/web/20130703151956im_/http://imagesak.roblox.com/437004fbc01bf6a613547a40aabde10a.jpg") repeat-x;
            padding-top: 35px;
            margin: 0;
            font-family: Arial, sans-serif;
        }
        #Container {
            background: url("https://web.archive.org/web/20130703151956im_/http://imagesak.roblox.com/161d0d393d74c103e5f50eef988b7217.png") repeat-x;
        }
        .site-header { width: 100%; background: #fff; }
        #navigation-container { width: 970px; margin: 0 auto; padding: 5px 0; }
        .btn-logo {
            display: inline-block;
            width: 150px; height: 50px;
            background: url("https://web.archive.org/web/20130703151956im_/http://www.roblox.com/images/logo.png") no-repeat;
        }
        #header-login-container { float: right; padding-top: 10px; }
        #header-signup { color: #0066cc; text-decoration: none; font-weight: bold; }
        #header-or { margin: 0 5px; color: #999; }
        .btn-control { cursor: pointer; color: #0066cc; font-weight: bold; }
        #Body { width: 970px; margin: 0 auto; }
        #Experimental { background: rgba(0,0,0,0.7); border-radius: 5px; margin: 20px auto; padding: 20px; width: 920px; }
        #Experimental .Content { color: #fff; }
        #animatedHeader { text-align: center; margin-bottom: 15px; }
        #headerLogo img { max-width: 200px; }
        #headerTextTop { font-size: 22px; font-weight: bold; color: #fff; }
        #headerTextBottom { font-size: 18px; color: #ccc; }
        #headerLoginText { text-align: right; }
        #headerLoginText a { color: #aaa; text-decoration: none; }
        #animatedBodyWrapper { display: flex; justify-content: center; gap: 20px; }
        #animatedBody { display: flex; gap: 20px; }
        .VideoContainer { flex: 1; }
        #slogan { font-size: 20px; font-weight: bold; color: #fff; margin-top: 10px; text-align: center; }
        .roblox-signup-wrapper { flex: 1; }
        #sign-up-wrapper { background: rgba(255,255,255,0.1); border-radius: 5px; padding: 15px; }
        #sign-up-title { font-size: 18px; font-weight: bold; color: #fff; margin-bottom: 10px; }
        .sign-up-row { margin-bottom: 10px; }
        .sign-up-inner-row { margin-bottom: 3px; color: #ccc; font-size: 13px; }
        .good-text { color: #0f0; font-size: 12px; }
        .required-text.error { color: #f00; font-size: 12px; }
        .text-box-large { width: 200px; padding: 4px; }
        .sign-up-description { font-size: 11px; color: #aaa; }
        select { padding: 3px; }
        .btn-large { display: inline-block; padding: 10px 25px; font-size: 16px; cursor: pointer; border-radius: 4px; border: none; }
        .btn-primary { background: #0077cc; color: #fff; text-decoration: none; }
        .btn-primary:hover { background: #005fa3; }
        .Footer.Experimental { background: rgba(0,0,0,0.5); color: #aaa; text-align: center; padding: 15px; margin-top: 20px; }
        .FooterParagraph a { color: #aaa; }
        .Legalese { font-size: 11px; }
        .Legalese a { color: #888; }
    </style>
</head>
<body>
    <div id="Container">
        <div class="site-header">
            <div id="navigation-container">
                <a href="/Default.aspx" class="btn-logo" data-se="nav-logo"></a>
                <div id="header-login-container">
                    <div id="header-login-wrapper">
                        <a id="header-signup" href="/Login/NewAge.aspx">Sign Up</a>
                        <span id="header-or">or</span>
                        <span id="login-span">
                            <a id="header-login" class="btn-control btn-control-large">Login <span class="grey-arrow">&#9660;</span></a>
                        </span>
                        <div id="iFrameLogin" style="display: none; height: 128px;" runat="server" clientidmode="Static">
                            <iframe class="login-frame" src="/Login/iFrameLogin" scrolling="no" frameborder="0"></iframe>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div style="clear:both"></div>

        <div id="Body" style="width:970px">
            <div id="Experimental" class="ShadowedStandardBox">
                <div class="Content">
                    <div id="animatedHeader">
                        <div id="headerLoginText"><a href="/Login/">Login</a></div>
                        <div id="headerLogo"><img src="https://web.archive.org/web/20130703151956im_/http://www.roblox.com/images/logo.png" alt="logo"></div>
                        <div id="headerTextTop">Join millions of builders</div>
                        <div id="headerTextBottom">and explore their creations</div>
                    </div>
                    <div id="animatedBodyWrapper">
                        <div id="animatedBody">
                            <div class="VideoContainer">
                                <object class="videoURL" data="https://www.youtube.com/v/LHdA7Yc-8Rg&fs=1&rel=0&autoplay=1" width="380" height="250">
                                    <param name="movie" value="https://www.youtube.com/v/LHdA7Yc-8Rg&fs=1&rel=0&autoplay=1">
                                    <param name="allowFullScreen" value="true">
                                    <param name="allowscriptaccess" value="always">
                                    <param name="wmode" value="transparent">
                                    <embed wmode="transparent" src="https://www.youtube.com/v/LHdA7Yc-8Rg&fs=1&rel=0&autoplay=1" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="380" height="250">
                                </object>
                                <div>
                                    <div id="slogan">What will you build?</div>
                                </div>
                            </div>
                            <div style="float: right;" class="roblox-signup-wrapper">
                                <div id="sign-up-wrapper">
                                    <form method="POST" id="signup-form" action="/landing/animated-signup">
                                        <div id="sign-up-title" class="sign-up-row">Sign up to build and play!</div>
                                        <div class="sign-up-row">
                                            <div class="sign-up-inner-row">
                                                <span id="birthdayGood" class="good-text" style="display: none;">OK</span>
                                                <span id="birthdayError" class="required-text error" style="display: none;"></span>
                                                <span id="birthdayText">Birthday</span>
                                            </div>
                                            <div>
                                                <select id="lstMonths" name="lstMonths" tabindex="1">
                                                    <option selected="selected" value="0">Month</option>
                                                    <option value="1">January</option><option value="2">February</option>
                                                    <option value="3">March</option><option value="4">April</option>
                                                    <option value="5">May</option><option value="6">June</option>
                                                    <option value="7">July</option><option value="8">August</option>
                                                    <option value="9">September</option><option value="10">October</option>
                                                    <option value="11">November</option><option value="12">December</option>
                                                </select>
                                                <select id="lstDays" name="lstDays" tabindex="2">
                                                    <option selected="selected" value="0">Day</option>
                                                    <% for (int d = 1; d <= 31; d++) { %><option value="<%=d%>"><%=d%></option><% } %>
                                                </select>
                                                <select id="lstYears" name="lstYears" tabindex="3">
                                                    <option selected="selected" value="0">Year</option>
                                                    <% for (int y = DateTime.Now.Year; y >= 1913; y--) { %><option value="<%=y%>"><%=y%></option><% } %>
                                                </select>
                                            </div>
                                            <div><span class="sign-up-description">Enter your birthday for a personalized experience.<br>It will not be given to any third party.</span></div>
                                        </div>
                                        <div class="sign-up-row">
                                            <div class="sign-up-inner-row">
                                                <span id="genderGood" class="good-text" style="display: none;">OK</span>
                                                <span id="genderError" class="required-text error" style="display: none;">Required</span>
                                                <span id="genderText">Gender</span>
                                            </div>
                                            <div>
                                                <input id="MaleBtn" name="gender" tabindex="4" type="radio" value="Male">
                                                <label for="MaleBtn">Male</label>
                                                <input id="FemaleBtn" name="gender" tabindex="5" type="radio" value="Female">
                                                <label for="FemaleBtn">Female</label>
                                            </div>
                                        </div>
                                        <div class="sign-up-row">
                                            <div class="sign-up-inner-row">
                                                <span id="usernameGood" class="good-text" style="display: none;">OK</span>
                                                <span id="usernameError" class="required-text error" style="display: none;"></span>
                                                <span id="usernameText">Username</span>
                                            </div>
                                            <div><input type="text" id="UserName" name="UserName" value="" class="text-box text-box-large" tabindex="6"></div>
                                            <div><span class="sign-up-description">3-20 alphanumeric characters, no spaces</span></div>
                                        </div>
                                        <div class="sign-up-row">
                                            <div class="sign-up-inner-row">
                                                <span id="passwordGood" class="good-text" style="display: none;">OK</span>
                                                <span id="passwordError" class="required-text error" style="display: none;"></span>
                                                <span id="passwordText">Password</span>
                                            </div>
                                            <div>
                                                <input name="password" value="" id="Password" class="text-box text-box-large" tabindex="7" type="password">
                                            </div>
                                            <div>
                                                <span class="sign-up-description">6-20 characters, minimum of 4 letters &amp; 2 numbers</span>
                                            </div>
                                        </div>
                                        <div class="sign-up-row">
                                            <div class="sign-up-inner-row">
                                                <span id="passwordConfirmGood" class="good-text" style="display: none;">OK</span>
                                                <span id="passwordConfirmError" class="required-text error" style="display: none;"></span>
                                                <span id="passwordConfirmText">Confirm Password</span>
                                            </div>
                                            <div>
                                                <input name="passwordConfirm" value="" id="PasswordConfirm" class="text-box text-box-large" tabindex="8" type="password">
                                            </div>
                                        </div>
                                        <div>
                                            <a id="SignUpButton" class="roblox-signup btn-large btn-primary" tabindex="9" href="#">
                                                Sign Up
                                            </a>
                                        </div>
                                    </form>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="Footer Experimental">
                <div class="FooterContent">
                    <p class="FooterParagraph">
                        <a href="/Info/Privacy.aspx"><b>Privacy Policy</b></a> &nbsp;|&nbsp;
                        <a href="/Parents.aspx">Parents</a> &nbsp;|&nbsp;
                        <a href="/Help/Builderman.aspx">Help</a>
                    </p>
                    <div class="FooterLegaleseContainer">
                        <p class="Legalese">
                            ROBLOX, "Online Building Toy", characters, logos, names, and all related indicia are trademarks of
                            <a href="http://corp.roblox.com/">ROBLOX Corporation</a>, &copy;2013. Patents pending.
                            Use of this site signifies your acceptance of the <a href="/info/terms-of-service">Terms and Conditions</a>.
                        </p>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script type="text/javascript">
        $(function () {
            $('#SignUpButton').click(function (e) {
                e.preventDefault();
                var valid = true;
                var username = $('#UserName').val().trim();
                var password = $('#Password').val();
                var passwordConfirm = $('#PasswordConfirm').val();
                var month = $('#lstMonths').val();
                var day = $('#lstDays').val();
                var year = $('#lstYears').val();
                var gender = $('input[name="gender"]:checked').val();

                if (!month || month == '0' || !day || day == '0' || !year || year == '0') {
                    $('#birthdayError').text('Required').show();
                    valid = false;
                } else { $('#birthdayError').hide(); $('#birthdayGood').show(); }

                if (!gender) {
                    $('#genderError').show(); valid = false;
                } else { $('#genderError').hide(); $('#genderGood').show(); }

                if (!username || username.length < 3) {
                    $('#usernameError').text('Required').show(); valid = false;
                } else { $('#usernameError').hide(); $('#usernameGood').show(); }

                if (!password || password.length < 6) {
                    $('#passwordError').text('Too short').show(); valid = false;
                } else { $('#passwordError').hide(); $('#passwordGood').show(); }

                if (password !== passwordConfirm) {
                    $('#passwordConfirmError').text('Does not match').show(); valid = false;
                } else { $('#passwordConfirmError').hide(); $('#passwordConfirmGood').show(); }

                if (valid) { $('#signup-form').submit(); }
            });
        });
    </script>
</body>
</html>
