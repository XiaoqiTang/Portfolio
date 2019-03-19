#1.1: Data Wrangling - Setup

library(corrplot)
library(caret) 
library(AppliedPredictiveModeling)
library(stargazer)
library(ggmap)
library(tidyverse)
library(sf)
library(FNN)
library(ggmap)
library(mapview)
library(devtools)
library(maps)
library(ggplot2)
mapTheme <- function(base_size = 12) {
  theme(
    text = element_text( color = "black"),
    plot.title = element_text(size = 14,colour = "black"),
    plot.subtitle=element_text(face="italic"),
    plot.caption=element_text(hjust=0),
    axis.ticks = element_blank(),
    panel.background = element_blank(),axis.title = element_blank(),
    axis.text = element_blank(),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(colour = "black", fill=NA, size=2)
  )
}

#load data
setwd("C:/Users/xiaoqi/Desktop/Ken/mid-term/")
zipcode <- st_read("download data/Zip Codes (GIS)/geo_export_11b22c7a-b867-41bf-8545-8b3d533072d9.shp")
#data <- read.csv("midtermData_forStudents/salesfinallllll.csv") 
st_crs(zipcode)==st_crs(biz)
#import dt& clear out NA
biz <- st_read("midtermData_forStudents/salesfinallllll.shp")
biz<- st_join(biz,zipcode)
#biz[biz==""]<- NA
#biz<-biz[!(rowSums(is.na(biz))),]

# basemap

ggplot()+
  geom_sf(data= zipcode, aes(), fill=NA ,colour="black") +
  geom_point(data=biz$SalePrice, 
           aes(Longitude,Latitude, color=factor(ntile(biz$SalePrice,5))),size=1) +
  labs(title="saleprice, Nashville") +
  scale_colour_manual(values = c("#ffffcc","#a1dab4","#41b6c4","#2c7fb8","#253494"),
                      labels=as.character(quantile(try1$SalePrice,
                                                   c(.1,.2,.4,.6,.8),na.rm=T)),
                      name="salepricee\nin thousands\n (Quintile Breaks)") +
  mapTheme()

library(mapview)
mapviewOptions(basemaps = c("OpenStreetMap.Tennessee"))

biz %>% 
  st_as_sf(coords=c("longitude","latitude"), crs="+proj=longlat +datum=WGS84") %>% 
  mapview(zcol="biz$SalePrice",legend=TRUE, alpha=0,cex=3, lwd=0) 


myMap <- get_map(location = "Nashville, Tennessee",
                 source = "google",
                 maptype = "terrain", crop = FALSE,
                 zoom = 6)
# plot map
ggmap(myMap)



ggmap() + 
  geom_point(data = try1, 
             aes(x=Longitude, y=Latitude, color=factor(ntile(SalePrice,5))), 
             size = 1) + 
  labs(title="saleprice, Nashville") +
  scale_colour_manual(values = c("#ffffcc","#a1dab4","#41b6c4","#2c7fb8","#253494"),
                      labels=as.character(quantile(try1$SalePrice,
                                                   c(.1,.2,.4,.6,.8),na.rm=T)),
                      name="salepricee\nin thousands\n (Quintile Breaks)") +
  mapTheme()

#together a proper dataset including the dependent and independent variables
names(biz)

biz <- biz %>%filter(roomsunits < 19 )
biz <- biz %>%filter(SalePrice > 0)
biz <- biz %>%filter(yearbuilt_ > 0)
  #var <- var %>%filter(roomsunits < 19 )

biz <-
  biz %>%
  mutate(yearbuilt_ = as.factor(yearbuilt_),
         LocationZi = as.factor(LocationZi),
         Logsale = log(SalePrice)) %>%
  as.data.frame() %>%
  select(-geometry) %>%
  filter(test == 0) %>%
  na.omit()


#biz <- biz[,c(2,5:12,18:29)]
names(biz)

#saleprice map

ggmap() + 
  geom_point(data = try1, 
             aes(x=Longitude, y=Latitude, color=factor(ntile(SalePrice,5))), 
             size = 1) + 
  labs(title="saleprice, Nashville") +
  scale_colour_manual(values = c("#ffffcc","#a1dab4","#41b6c4","#2c7fb8","#253494"),
                      labels=as.character(quantile(try1$SalePrice,
                                                   c(.1,.2,.4,.6,.8),na.rm=T)),
                      name="salepricee\nin thousands\n (Quintile Breaks)") +
  mapTheme()


#1.2: Data Wrangling - Exploratory analysis

# table of summary statistics
stargazer(biz, type="text", title = "Summary Statistics")

#correlations 
M <- cor(biz)
unlist(lapply(biz, class))

bizCor <- select(biz, -kenID, -roomsunits, -baths, -sf_finishe, -college_co, -objectid, -shape_star, -shape_stle, -test, -WGS1984X, -WGS1984Y,-Story_Heig,-SalePrice,-zip,-po_name,-yearbuilt_,-LandUseFul,-LocationZi,-LocationCi,-zip)
M <- cor(bizCor)
corrplot(M, method = "number")

names(biz)
#regression
reg <- lm(Logsale ~ ., data=biz %>% select(-test, -kenID, -SalePrice,-WGS1984X, -WGS1984Y,-zip,-po_name,-objectid,-shape_star,-shape_stle))
summary(reg)
mean(abs(exp(reg$fitted.values) - biz$Logsale) / biz$SalePrice)
mean(regPredValues$percentAbsError)
#2.1: Modeling - In-sample prediction

#prediction equals the observed value
regDF <- cbind(biz$Logsale, reg$fitted.values)
colnames(regDF) <- c("Observed", "Predicted")
regDF <- as.data.frame(regDF)
ggplot() + 
  geom_point(data=regDF, aes(Observed, Predicted)) +
  stat_smooth(data=regDF, aes(Observed, Observed), method = "lm", se = FALSE, size = 1, colour="red") + 
  stat_smooth(data=regDF, aes(Observed, Predicted), method = "lm", se = FALSE, size = 1, colour="blue") + 
  labs(title="Predicted Sales Price as a function\nof Observed Sales Price",
       subtitle="Perfect prediction in red; Actual prediction in blue") +
  theme(plot.title = element_text(size = 18,colour = "black"))

#add the Dunkin' Donuts fixed effect

biz <- 
  biz %>%
  mutate(issinglefamily = as.factor(ifelse(LandUseFul == "SINGLE FAMILY' RESIDENTIAL CONDO" ,1,0)))

reg2 <- lm(SalePrice ~ ., data=biz %>% select(-test, -WGS1984X, -WGS1984Y))
summary(reg2)

#histogram of our errors or residuals

hist(abs(biz$SALES_VOL - reg2$fitted.values), breaks=50, main="Histrogram of residuals (absolute values)")


#2.2: Modeling - Out-of-sample prediction

inTrain <- createDataPartition(
  y = biz$SALES_VOL, 
  p = .75, list = FALSE)
training <- biz[ inTrain,] #the new training set
test <- biz[-inTrain,]  #the new test set

#new training set
reg3 <- lm(SALES_VOL ~ distHwy + CoffeeDist + DistShop + popDens + POP + HHs + Families + Homes + Med_Inc + Med_Rent + Med_Value + Pct_White + Pct_le_5yr + Avg_HHSze + Pct_Col2 + Pct_BlPov + distEmpC + NUMBER_EMP + isDunkin, 
           data = training)

#predict dependent for the test set
reg3Pred <- predict(reg3, test) 

#creating a new data frame of the predicted and observed SALES_VOL for the test set
reg3PredValues <- 
  data.frame(observedSales = test$SALES_VOL,
             predictedSales = reg3Pred)

reg3PredValues <-
  reg3PredValues %>%
  mutate(error = predictedSales - observedSales) %>%
  mutate(absError = abs(predictedSales - observedSales)) %>%
  mutate(percentAbsError = abs(predictedSales - observedSales) / observedSales) 

head(reg3PredValues)

#create some aggregate
mean(reg3PredValues$absError)
mean(reg3PredValues$percentAbsError)





#predictors <- as.matrix(cbind(data1$SalePrice, data1$Acrage, data1$Story_Heig, data1$roomsunits, data1$sf_finishe, data1$bedroomsun, data1$baths, data1$dis_crime, data1$dis_transit, data1$dis_cbd, data1$dis_park, data1$dis_lib, data1$dis_lib, data1$dis.grocery, data1$dis.office, data1$Sumcrash))
#cor(predictors, method = ("pearson"))

#reg <- lm(SalePrice ~ distHwy + CoffeeDist + DistShop + popDens +   POP + HHs + Families + Homes + Med_Inc + Med_Rent   +
           # Med_Value + Pct_White + Pct_le_5yr + Avg_HHSze + Pct_Col2 + Pct_BlPov + distEmpC + NUMBER_EMP, 
         # data = biz) 

#reg1 <- lm(log(SalePrice) ~ ., data=data1 %>% select(-test, -WGS1984X, -WGS1984Y))
#mean(abs(exp(reg1$fitted.values) - vars1$SalePrice) / vars1$SalePrice)

#fit1 <- lm(formula = data1$SalePrice ~ data1$Acrage + data1$Story_Heig + data1$roomsunits + data1$sf_finishe + data1$bedroomsun, data=RegressionData)
#summary(fit1)

#anova(fit1)

#stargazer(data1, type="text", title = "Summary Statistics")

#data1 <- read.csv("midtermData_forStudents/train.and.test_student.csv", header= TRUE, sep=",",skipNul = TRUE)
#data1[data1==""]<- NA
#data1<-data1[!(rowSums(is.na(data1))),]


#var1 <- read.table("midtermData_forStudents/1.csv",header= TRUE, sep=",",skipNul = TRUE)
#var1[var1==""]<- NA
#var1<-var1[!(rowSums(is.na(var1))),]

#hist(data$LocationCity, breaks = 20, main = paste("Histogram of MEDHVAL"), xlab = "data$LocationCity")








#var1$Story_Height<- gsub("STORY","",var1$Story_Height)

#sales <- st_read("sales.shp")

#st_crs(zipcode)== st_crs(sales)
#names(sales)




