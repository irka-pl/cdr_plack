## Hello Petr and Elder Studios Team,

Although I see application as not completed and it doesn't fulfill task requirements, at least it provides less than 6-7 API entry points, I think it is time to present it anyway. I spent much more than 7 hours on it during these 3 weekends, and I don't want to make you wait more.

#### Let me describe what app does, what it is going to do in the future, and why it took so much time.

Currently cdr interface allows to upload csv file using POST method. It doesn't check file format and naively believes that it is csv.
It tries to guess columns locations by name aliases. But it doesn't try to guess columns by data format,and I think it shouldn't. POST method also doesn't allow one row json data processing, but I'm going to implement it.

POST method collects all lines that it couldn't insert due to the data incorrectness or data duplication.It returns this information in the response body. cdr table should be huge on production systems, and indexes should significantly slow down insertion. Nevertheless for this task I decided to use unique index for the call start date time (counted field) and caller id (I decided that one number can't start some calls simultaneously). I prepared method to try multiple inserts in one query, just to compare insertion speed, but didn't test it yet.

GET method uses generic get functionality with filters, that could be provided as query parameters with special naming. It doesn't support sorting and paging now, but will do in the future.
Now GET method returns json data. In the future it also should return text/csv data if user provided Accept header with proper content type.

I postponed application configuration handling, although every time I hard-coded some values I felt absence of the configuration implementation. The most often "todo" tag in the code is about configuration.

I didn't test properly some design solution, e.g. plack request/response ownership. Probably these object could be located in the app, but I wasn't sure about their state in that case, although logically I don't see reasons for such doubts.

At all there are still a lot of things to do.

#### Some design decisions.

Application is written in old-fashioned style, it doesn't use modern perl. There were two reasons: I wanted to created as lightweight app with as less dependencies, as I could. Second reason was that although we used modern perl (Moo, Moose) a lot in the Cisco and Sipwise, I still feel the most confident with pure perl, and can write this simple code the fastest.

As test database I choose SQLite, from all file databases I know this one as the most reach of the features. Also I supposed that I may want to deploy app, and file database seemed to me as the most easy to deploy variant.

As a bonus result I wanted to create small MVC framework that would allow to create web applications and api's just defining non trivial behavior, covering all usual functionality by the framework. 

I decided to don't use any ready framework. As the most close to the test task needs I found Raisin, also I was very interested in the experience with asynchronous work in Mojoliciouse. But I decided to use plack solution as the simplest variant, with low risk that I will stuck with some feature due to my weak framework knowledge. For the production solution I would spend even more time on the framework selection and choose one of them for sure. 

I wanted to avoid ORM using to keep application small. I reimplemented ideas from my old (2005) web framework with very basic sql generation, that could be replaced by the manually written sql for more complex cases. I remember that simple filter & sorting & paging sql generation covered > 80 needs of the usual web applications, and allowed to keep code base small.

Now application uses primitive validation, from the method located right in the API interface module. This should change in the future. Validation should be separated and use some library solution, probably input::validate. When I was working with Data::Validator, I always was sorry about data, once collected for the validation purposes, that weren't used for the further data processing. And I want to construct data validation so results of the validation processing could be reused.

There are some SQLite specific code presented in the generic methods, it also should be separated.

I didn't find a cloud to deploy the app yet and will write you additionally if I will deploy it somewhere.

At the end I wont to thank you for this interesting task.

Best regards,
Irina