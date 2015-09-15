library(httr)
library(XML)
library(httpuv)
library(RJSONIO)
library(ggplot2)
library(rvest)

#store they key in the text files, or paste them in here.
creds <- read.csv("C:/Users/Brooke/Downloads/YahooAPI.csv", stringsAsFactors=F)
consumer.key <- creds[1,2]
consumer.secret <- creds[2,2]


#standard authorization steps from httr
yahoo<-oauth_endpoints("yahoo")
myapp <- oauth_app("yahoo", key = consumer.key, secret = consumer.secret)
token <- oauth1.0_token(oauth_endpoints("yahoo"), myapp, as_header = FALSE, cache = FALSE)

# need to get game id for my league...
ff.url <- "http://fantasysports.yahooapis.com/fantasy/v2/game/nfl?format=json"
game.key.json <- GET(ff.url, config(token = token))
game.key.list <- fromJSON(as.character(game.key.json), asText=T)
game.key <- game.key.list$fantasy_content$game[[1]]["game_key"]

# my personal leagueid, you will have to use your own, mine is private
game.id <- "348"
game.key <- game.id
game.url <- "http://fantasysports.yahooapis.com/fantasy/v2/game/"



# my personal leagueid, you will have to use your own, mine is private
league.id <- "982118"
league.key <- paste0(game.key, ".l.", league.id)
league.url <- "http://fantasysports.yahooapis.com/fantasy/v2/league/"

my.team.id <- "2"
my.team.key <- paste0(league.key, ".t.", my.team.id)
team.url <- "http://fantasysports.yahooapis.com/fantasy/v2/team/"

#getting transactions although the process works well for digging into most collections
responseAllTeams<- html(paste0(league.url, league.key, "/teams"), config(token = token))
#responseAllTeams %>% xml_structure()
Name <- responseAllTeams %>% html_nodes('name')

responseAllPlayersOnRoster<- html(paste0(team.url, my.team.key, "/roster/players"), config(token = token))
#responseAllPlayersOnRoster %>% xml_structure()
#Players <- responseAllPlayers %>% html_nodes('player')
Names.df <- responseAllPlayersOnRoster %>% html_nodes('player') %>% html_nodes('full') %>% html_text()
Position.df <- responseAllPlayersOnRoster %>% html_nodes('player') %>% html_nodes('selected_position')%>% html_nodes('position') %>% html_text()
Roster.df <- data.frame(Names.df,Position.df)

url <- paste0(league.url, league.key,"/players?&status=A&stat1=S_PW_1&start=37")
responseAllPlayersFree <- html("http://fantasysports.yahooapis.com/fantasy/v2/league/348.l.982118/players?&status=A&start=0&stat1=S_PW_1",config(token=token))
responseAllPlayersFree<- html(url, config(token = token))
#responseAllPlayersFree %>% xml_structure()
#NamesFree.df <- responseAllPlayersFree %>% html_nodes('players') %>% html_nodes('full') %>% html_text()
#PositionFree.df <- responseAllPlayersFree %>% html_nodes('players') %>%  html_nodes('eligible_positions') %>% html_text()
#AllPlayersFree <- data.frame(NamesFree.df,PositionFree.df)

baseurl <- "http://fantasysports.yahooapis.com/fantasy/v2/league/348.l.982118/players?&status=A"
playerCount <- paste("&start=",seq(0,1050,by=25),sep="")
#PWeekCount<-paste("&stat1=S_PW_",1:17,sep="")
YahooURLs <- unlist((paste(baseurl,playerCount,sep="")))

yahooHTML<-lapply(YahooURLs,function(x) {Sys.sleep(abs(rnorm(1)*4+7));html(x, config(token = token))})


for (i in 1:(length(yahooHTML)) ) {
  Names <- yahooHTML[[i]] %>% html_nodes('players') %>% html_nodes('full') %>% html_text()
  Player_id <- yahooHTML[[i]] %>% html_nodes('players') %>% html_nodes('player_id') %>% html_text()
  Position <- yahooHTML[[i]] %>% html_nodes('players') %>%  html_nodes('position_type') %>% html_text()
  Eligible <- yahooHTML[[i]] %>% html_nodes('players') %>%  html_nodes('eligible_positions') %>% html_text()
  ByeWeek <- yahooHTML[[i]] %>% html_nodes('players') %>%  html_nodes('bye_weeks') %>% html_text()
  IsDroppable <- yahooHTML[[i]] %>% html_nodes('players') %>%  html_nodes('is_undroppable') %>% html_text()
  Team <- yahooHTML[[i]] %>% html_nodes('players') %>%  html_nodes('editorial_team_full_name') %>% html_text()
  #Notes <- yahooHTML[[i]] %>% html_nodes('players') %>%  html_nodes('has_player_notes') %>% html_text()
    if (i == 1) {AllPlayersFree <- data.frame(Names,Player_id,Position,Team,Eligible,ByeWeek,IsDroppable)}
  else {AllPlayersFree <- rbind(AllPlayersFree,data.frame(Names,Player_id,Position,Team,Eligible,ByeWeek,IsDroppable))}
rm(Names)
rm(Player_id)
rm(Position)
rm(Eligible)
rm(ByeWeek)
rm(IsDroppable)
rm(Team)
#rm(Notes)


}
  