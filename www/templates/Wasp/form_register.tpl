[css:navigation.css]
[css:login.css]

<div class="login">
  <div class="ui">
    <a class="ui" href="/">Threads</a>
  </div>
  <form class="register-block" method="post" action="/!register/">
    <h1>Register</h1>
    <input type="text" value="" placeholder="Username" name="username" class="username" maxlength="256" autofocus>
    <input type="text" value="" placeholder="e-mail" name="email" class="email" maxlength="320">
    <input type="password" value="" placeholder="Password" name="password" class="password" maxlength="1024" autocomplete="off">
    <input type="password" value="" placeholder="Password again" name="password2" class="password" maxlength="1024" autocomplete="off">
    <input type="hidden" value="[ticket]" name="ticket" id="ticket">
    <input type="submit" name="submit" class="submit" value="Submit">
  </form>
  <article>
    <p>To choose strong password and write it down on a paper is better than to choose easy to remember password.</p>
    <p>Because the humans are not very good in remembering random strings, but pretty good in keeping small sheets of paper.</p>
    <p>But don't stick it on your monitor. Simply keep it in your wallet...</p>
    <p>... or use some password manager program.</p>
  </article>
</div>
