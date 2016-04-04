<div class="new_editor">
  <div class="ui">
    <a class="ui" href="/list/[special:urltag]">Thread list</a>
  </div>
  <form id="editform" action="/post/[special:urltag]" method="post">
    <div class="edit_groupL">
      <p>Title:</p>
      <input class="title" type="edit" value="[caption]" placeholder="Thread title" name="title" autofocus="on">
    </div><div class="edit_groupR">
      <p>Tags: <span class="small">(max 3, comma delimited, no spaces)</span> [case:[special:tag]| |+ "[special:tag]"]</p>
      <input class="tags"  type="edit" value="[tags]" name="tags" placeholder="some tags here"><br>
    </div>
    <p>Post content:</p>
    <textarea class="editor" name="source" id="source" placeholder="Share you thoughs here">[source]</textarea><br>
    <div class="panel">
      <input type="submit" name="submit" value="Submit" >
      <input type="submit" name="preview" value="Preview" >
      <input type="hidden" name="ticket" value="[Ticket]" >
      <input type="reset" value="Revert" >
    </div>
  </form>
</div>
