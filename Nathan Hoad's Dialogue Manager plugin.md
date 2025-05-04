# **Basic Dialogue**

Navigate to the "Dialogue" tab in the editor.

![Dialogue tab][image1]

Open some dialogue by clicking the "new dialogue file" button or "open dialogue" button.

![New and Open buttons][image2]

The most basic dialogue is just a string:

This is some dialogue.

If you want to add a character that's doing the talking then include a name before a colon and then the dialogue:

Nathan: This is me talking.

You can add some spice to your dialogue with [BBCode](https://docs.godotengine.org/en/stable/tutorials/ui/bbcode_in_richtextlabel.html#reference). Along with everything available to Godot's RichTextLabel you can also use a few extra ones provided by Dialogue Manager:

* \[\[This|Or this|Or even this\]\] to pick one option at random in the middle of dialogue (note the double "\[\[").  
* \[wait=N\] where N is the number of seconds to pause typing of dialogue.  
* \[speed=N\] where N is a number to multiply the default typing speed by.  
* \[next=N\] where N is a number of seconds to wait before automatically continuing to the next line of dialogue. You can also use \[next=auto\] to have the label determine a length of time to wait based on the length of the text.

Lines of dialogue are written one after another:

Nathan: I'll say this first.  
Nathan: Then I'll say this line.

To add some interactivity to the dialogue you can specify responses. Responses are lines that begin with a \- :

\- This is a response  
\- This is a different response  
\- And this is the last one

## **Responses**

One way of branching the dialogue after a response is to nest some more dialogue below each response. Nested response dialogue can nest indefinitely as more and more branches get added

Nathan: How many projects have you started and not finished?  
\- Just a couple  
	Nathan: That's not so bad.  
\- A lot  
	Nathan: Maybe you should finish one before starting another one.  
\- I always finish my projects  
	Nathan: That's great\!  
	Nathan: ...but how many is that?  
	\- A few  
		Nathan: That's great\!  
	\- I haven't actually started any  
		Nathan: That's what I thought.

Responses can include conditions that determine if they are selectable. To include a condition in a response, add a condition expression wrapped in square brackets, like this:

\- This is a normal response  
\- This is a conditional response \[if SomeGlobal.some\_property \== true\]

## **Randomising lines of dialogue**

If you want to pick a random line out of multiple, you can mark the lines with a % at the start like this:

Nathan: I will say this.  
% Nathan: And then I might say this  
% Nathan: Or maybe this  
% Nathan: Or even this?

Each line will have an equal chance of being said.

To weight lines, use a % followed by a number to weight by. For example, a %2 will mean that line has twice the chance of being picked as a normal line.

%3 Nathan: This line has a 60% chance of being picked  
%2 Nathan: This line has a 40% chance of being picked

To separate multiple groups of random lines, use an empty line:

% Group 1  
% Also group 1

% Group 2  
% And this is also group 2

You can also have whole blocks be random:

%  
	Nathan: This is the first block.  
	Nathan: Still the first block.  
% Nathan: This is the possible outcome.

If the first random item is chosen it will play through both nested lines.

## **Variables in dialogue**

To show some value of game state within a line of dialogue, wrap it in double curlies.

Nathan: The value of some property is {{SomeGlobal.some\_property}}.

Similarly, if the name of a character is based on a variable you can provide it in double curlies too:

{{SomeGlobal.some\_character\_name}}: My name was provided by the player.

## **Tags**

If you need to annotate your lines with tags, you can wrap them in \[\# and \], separated by commas. So to specify "happy" and "surprised" tags for a line, you would do something like:

Nathan: \[\#happy, \#surprised\] Oh, Hello\!

At runtime, the DialogueLine's tags property would include \["happy", "surprised"\].

You can also give tags values that can be accessed with the get\_tag\_value method on a DialogueLine:

Nathan: \[\#mood=happy\] Oh, Hello\!

For this line of dialogue, the tags array would be \["mood=happy"\], and line.get\_tag\_value("mood") would return "happy".

## **Simultaneous dialogue**

If you would like multiple characters to speak at once the you can use the concurrent lines syntax. After a regular line of dialogue any lines that are to be spoken at the same time as it can be prefixed with "| ".

Nathan: This is a regular line of dialogue.  
| Coco: And I'll say this line at the same time\!  
| Lilly: And I'll say this too\!

To use concurrent line, access the concurrent\_lines property on a DialogueLine.

*NOTE: In an effort to keeps things simple, the built-in example balloon does not contain an implementation for concurrent lines.*

## **Titles and Jumps**

Titles are markers within your dialogue that you can start from and jump to. Usually, in your game you would start some dialogue by providing a title (the default title is start but it could be whatever you've written in your dialogue).

Titles start with a \~  and are named (without any spaces):

\~ this\_is\_a\_title

To jump to a title from somewhere in dialogue you can use a jump/goto line. Jump lines are prefixed with a \=\>  and then specify the title to go to.

\=\> this\_is\_a\_title

When the dialogue runtime encounters a jump it will then direct the flow to that title marker and continue from there.

If you want to end the flow from within the dialogue you can jump to END:

\=\> END

This will end the current flow of dialogue.

You can also use a "jump and return" kind of jump that redirects the flow of dialogue and then returns to where it jumped from. Those lines are prefixed with \=\>\<  and then specify the title to jump to. Once the flow encounters an END (or the end of the file) flow will return to where it jumped from and continue from there.

If you want to force the end of the conversation regardless of any chained "jump and returns", you can use an \=\> END\! line.

Jumps can also be used inline for responses:

\~ start  
Nathan: Well?  
\- First one  
\- Another one \=\> another\_title  
\- Start again \=\> start  
\=\> END

\~ another\_title  
Nathan: Another one?  
\=\> END

### **Expression Jumps**

You can use expressions as jump directives. The expression needs to resolve to a known title name or results will be unexpected.

Use these with caution as the dialogue compiler can't verify expression values match any titles at compile time.

Expression jumps look something like:

\=\> {{SomeGlobal.some\_property}}

## **Importing dialogue into other dialogue**

If you have a dialogue file that contains common dialogue that you want to use in multiple other files you can import it into those files.

For example, we can have a snippets.dialogue file:

\~ banter  
Nathan: Blah blah blah.  
\=\> END

Which we can then import into another dialogue file and jump to the banter title from the snippets file (note the \=\>\< syntax which denotes to return to this line after the jumped dialogue finishes):

import "res://snippets.dialogue" as snippets

\~ start  
Nathan: The next line will be from the snippets file:  
\=\>\< snippets/banter  
Nathan: That was some banter\!  
\=\> END

# **Conditions & Mutations**

## **Conditions**

### **If/else**

You can use conditional blocks to further branch your dialogue. Start a condition line with "if" and then provide an expression. You can compare variables or function results.

Additional conditions use "elif" and you can use "else" to catch any other cases.

if SomeGlobal.some\_property \>= 10  
    Nathan: That property is greater than or equal to 10  
elif SomeGlobal.some\_other\_property \== "some value"  
    Nathan: Or we might be in here.  
else  
    Nathan: If neither are true, I'll say this.

*Note: To escape a condition line (i.e. if you wanted to start a dialogue line with "if"), you can prefix the condition keyword with a "".*

Responses can also have "if" conditions. Wrap these in "\[" and "\]".

Nathan: What would you like?  
\- This one \[if SomeGlobal.some\_property \== 0 or SomeGlobal.some\_other\_property \== false\]  
    Nathan: Ah, so you want this one?  
\- Another one \[if SomeGlobal.some\_method()\] \=\> another\_title  
\- Nothing \=\> END

If using a condition and a goto on a response line, make sure the goto is provided last.

Conditions can also be used inline in a dialogue line when wrapped with "\[if predicate\]" and "\[/if\]".

Nathan: I have done this \[if already\_done\]once again\[/if\]

For simple this-or-that conditions, you can write them like this:

Nathan: You have {{num\_apples}} \[if num\_apples \== 1\]apple\[else\]apples\[/if\], nice\!

Randomised lines and randomised jump lines can also have conditions. Conditions for randomised lines go in square brackets after the % and before the line's content:

% \=\> some\_title  
%2 \=\> some\_other\_title  
% \[if SomeGlobal.some\_condition\] \=\> another\_title

### **Match**

To shortcut some if/elif/elif/elif chains you use a match line:

match SomeGlobal.some\_property  
    when 1  
        Nathan: It is 1\.  
    when \> 5  
        Nathan: It is less than 5 (but not 1).  
    else  
        Nathan: It was something else.

### **While**

You can also start a conditional block with "while". These blocks will loop as long as the condition is true.

while SomeGlobal.some\_property \< 10  
    Nathan: The property is still less than 10 \- specifically, it is {{SomeGlobal.some\_property}}.  
    do SomeGlobal.some\_property \+= 1  
Nathan: Now, we can move on.

## **Mutations**

You can affect state with either a "set" or a "do" line.

if SomeGlobal.has\_met\_nathan \== false  
    do SomeGlobal.animate("Nathan", "Wave")  
    Nathan: Hi, I'm Nathan.  
    set SomeGlobal.has\_met\_nathan \= true  
Nathan: What can I do for you?  
\- Tell me more about this dialogue editor

In the example above, the dialogue manager would expect a global called SomeGlobal to implement a method with the signature func animate(string, string) \-\> void.

You can pass an array of nodes/objects as the extra\_game\_states parameter when [requesting a line of dialogue](https://github.com/nathanhoad/godot_dialogue_manager/blob/main/docs/API.md#func-get_next_dialogue_lineresource-resource-key-string--0-extra_game_states-array-----dictionary) which will also be checked for possible mutation methods.

Mutations can also be used inline. Inline mutations will be called as the typed out dialogue reaches that point in the text.

Nathan: I'm not sure we've met before \[do wave()\]I'm Nathan.  
Nathan: I can also emit signals\[do SomeGlobal.some\_signal.emit()\] inline.

Inline mutations that use await in their implementation will pause typing of dialogue until they resolve. To ignore awaiting, add a "\!" after the "do" keyword \- e.g. \[do\! something()\].

### **Signals**

Signals can be emitted similarly to how they are emitted in GDScript \- by calling emit on them.

For example, if SomeGlobal has a signal called some\_signal that has a single string parameter, you can emit it from dialogue like this:

do SomeGlobal.some\_signal.emit("some argument")

### **Null coalescing**

In some cases you might want to refer to properties of an object that may or may not be defined. This is where you can make use of null coalescing:

if some\_node\_reference?.name \== "SomeNode"  
    Nathan: Notice the "?." syntax?

If some\_node\_reference is null then the whole left side of the comparison will be null and, therefore, not be equal to "SomeNode" and fail. If the null coalescing isn't used here and some\_node\_reference is null then the game will crash.

### **State shortcuts**

If you want to shorten your references to state from something like SomeGlobal.some\_property to just some\_property, there are two ways you can do this.

1. If you use the same state in all of your dialogue, you can set up global state shortcuts in [Settings](https://github.com/nathanhoad/godot_dialogue_manager/blob/main/docs/Settings.md).  
2. Or, if you want different shortcuts per dialogue file, you can add a using SomeGlobal clause (for whatever autoload you're using) at the top of your dialogue file.

## **Special variables/mutations**

There are a couple of special built-in mutations you can use:

* do wait(float) \- wait for float seconds (this has no effect when used inline).  
* do debug(...) \- print something to the Output window.

There is also a special property self that you can use in dialogue to refer to the DialogueResource that is currently being run.

# **Using dialogue in your game**

The simplest way to show dialogue in your game is to call [DialogueManager.show\_dialogue\_balloon(resource, title)](https://github.com/nathanhoad/godot_dialogue_manager/blob/main/docs/API.md#func-show_dialogue_balloonresource-dialogueresource-title-string--0-extra_game_states-array-----node) with a dialogue resource and a title to start from. This will show the example balloon by default but you can configure it in [Settings](https://github.com/nathanhoad/godot_dialogue_manager/blob/main/docs/Settings.md) to show your custom balloon.

It's up to you to implement/customise any dialogue rendering and input control to match your game. There are a few example projects available on [my Itch.io page](https://nathanhoad.itch.io/) to get you started though.

Once you get to the stage of building your own balloon, you'll need to know how to get a line of dialogue and how to use the dialogue label node.

## **Getting a line of dialogue**

A global called DialogueManager is available to provide lines of dialogue.

To request a line, call await DialogueManager.get\_next\_dialogue\_line(resource, title) with a dialogue resource (\*.dialogue file) and a starting title (you can also call get\_next\_dialogue\_line on the resource directly, see below). This will traverse each line (running mutations along the way) and returning the first printable line of dialogue.

For example, if you have some dialogue like:

\~ start

Nathan: Hi\! I'm Nathan.  
Nathan: Here are some options.  
\- First one  
	Nathan: You picked the first one.  
\- Second one  
	Nathan: You picked the second one.

And then in your game:

var resource \= load("res://some\_dialogue.dialogue")  
\# then  
var dialogue\_line \= await DialogueManager.get\_next\_dialogue\_line(resource, "start")  
\# or  
var dialogue\_line \= await resource.get\_next\_dialogue\_line("start")

Then dialogue\_line would now hold a DialogueLine containing information for the line Nathan: Hi\! I'm Nathan.

To get the next line of dialogue, you can call get\_next\_dialogue\_line again with dialogue\_line.next\_id as the title:

dialogue\_line \= await DialogueManager.get\_next\_dialogue\_line(resource, dialogue\_line.next\_id)  
\# or  
dialogue\_line \= await resource.get\_next\_dialogue\_line(dialogue\_line.next\_id)

Now dialogue\_line holds a DialogueLine containing the information for the line Nathan: Here are some options.. This object also contains the list of response options.

Each option also contains a next\_id property that can be used to continue along that branch.

For more information about DialogueLines, see the [API documentation](https://github.com/nathanhoad/godot_dialogue_manager/blob/main/docs/API.md).

## **DialogueLabel node**

The addon provides a DialogueLabel node (an extension of the RichTextLabel node) which helps with rendering a line of dialogue text.

This node is given a dialogue\_line (mentioned above) and uses its properties to work out how to handle typing out the dialogue. It will automatically handle any bb\_code, wait, speed, and inline\_mutation references.

Use type\_out() to start typing out the text. The label will emit a finished\_typing signal when it has finished typing.

The label will emit a paused\_typing signal (along with the duration of the pause) when there is a pause in the typing and a spoke signal (along with the letter typed and the current speed) when a letter was just typed.

The DialogueLabel typing speed can be configured in your balloon by changing the seconds\_per\_step property. It will also automatically wait for a brief time when it encounters characters specified in the pause\_at\_characters property (by default, just ".").

## **Using a custom current\_scene implementation**

If your game has its own method of managing what the "current scene" is, you might want to pass an overridden Callable to DialogueManager.get\_current\_scene. The built-in implementation looks at get\_tree().current\_scene before assuming the last child of get\_tree().root is the current scene. If that doesn't work for your game, you can pass in a Callable that returns a Node that represents what the current scene is.

## **Generating Dialogue Resources at runtime**

If you need to construct a dialogue resource at runtime, you can use create\_resource\_from\_text(string):

var resource \= DialogueManager.create\_resource\_from\_text("\~ title\\nCharacter: Hello\!")

This will run the given text through the dialogue compiler.

If there were syntax errors, the method will fail.

If there were no errors, you can use this ephemeral resource like normal:

var dialogue\_line \= await resource.get\_next\_dialogue\_line("title")

[image1]: <data:image/png;base64,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>

[image2]: <data:image/png;base64,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>