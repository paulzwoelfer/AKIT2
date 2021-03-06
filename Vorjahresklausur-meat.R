# AKIT2 SS18, Nachklausur (2. Termin), 19.9.2018
library(ggplot2)
library(car)
library(corrplot)
library(effects)
library(pwr)
library(ROCR)
library(runjags)
library(coda)
rjags::load.module("glm")
library(akit2)
library(psych)

# Wir arbeiten in einem industriellen Fleischbetrieb, bei dem fein gehacktes Fleisch
# verarbeitet wird. Der Fettgehalt des Fleisches bestimmt seinen Verkaufswert.
# Mithilfe von Infrarot-Messger�ten kann der Fettgehalt bestimmt werden. Wir
# wollen neue Messger�te anschaffen und haben uns von drei Herstellern
# Testger�te liefern lassen. Mit den drei Testger�ten machen wir eine Reihe von Tests
# zur Bestimmung des Fettgehalts.

df <- read.csv('C:\\Users\\Dominik\\Downloads\\meat.csv')
#Wir haben hier 13 metrische Variablen

mapply(hist, as.data.frame(df), main = colnames(df))
describe(df)
#Bei der ersten durchsicht ist aufgefallen das manche Messpunkte weit au�erhalb liegen.
#Das k�nnen Messfehler sein oder fehlendes Dom�nenwissen.

# Der Datensatz enth�lt:
# - fat ... Fettgehalt
# - g1w1-g1w4 ... 4 Messwerte des Messger�ts 1 (aus dem Infrarotspektrum 850-1050nm)
# - g2w1-g2w4 ... 4 Messwerte des Messger�ts 2 (-"-)
# - g3w1-g3w4 ... 4 Messwerte des Messger�ts 3 (-"-)


# Schritt 1: Verwenden Sie nur die ersten 175 Datens�tze.
#            Erstellen Sie die linearen Modelle und verifizieren Sie diese.

dfn = df[1:175,]
mapply(hist, as.data.frame(dfn), main = colnames(dfn))
#Nach der k�rzung sehen einige Datens�tze noch immer schlecht aus.
#g1w1, g1w3, g2w2
#Nach erster Druchsicht sind die meisten Datens�tze wohl im Wertebereich -4 bis 8.

sum(dfn$g1w1>8)
#1 Ausrei�er �ber 8
sum(dfn$g1w3>8)
#1 Ausrei�er �ber 8
sum(dfn$g2w2<(-4))
#1 Ausrei�er unter -4

model1 = lm(fat ~ g1w1 + g1w2 + g1w3 + g1w4, data = dfn)
model2 = lm(fat ~ g2w1 + g2w2 + g2w3 + g2w4, data = dfn)
model3 = lm(fat ~ g3w1 + g3w2 + g3w3 + g3w4, data = dfn)

# Schritt 2: Vergleichen Sie die erstellten Modelle.
#            Auf Basis dieses Vergleichs: welches Messger�t w�rden Sie kaufen?

#------------ Model1 --------------#
summary(model1)
#model1 erkl�rt nur 2% der Varianz.
vif(model1)
#Alle Werte befinden sich unter 5 daher ist nur eine Geringe Abh�ngigkeit zu bemerken
par(mfrow=c(2,2))
plot(model1)
#Kein Muster erkennbar.
qqp(model1)
#Sieht nicht gut aus!
crPlots(model1)
#pinke Linie weicht von blauer ab. Nicht gut.
outlierTest(model1)
#Wir haben wohl Ausrei�er!
plot(model1, which=4)
#Datensatz 1 und 118 sind Ausrei�er
plot(model1, which=5)
#Auch hier Datensatz 1 und 118

#------------ Model2 --------------#
summary(model2)
#model2 erkl�rt nur 3% der Varianz.
vif(model2)
#Alle Werte befinden sich unter 5 daher ist nur eine Geringe Abh�ngigkeit zu bemerken
par(mfrow=c(2,2))
plot(model2)
#Es ist ein Muster zu erkennen aber ich kann es nicht einordnen.
qqp(model2)
#Sieht nicht gut aus!
crPlots(model2)
#pinke Linie weicht von blauer ab. Nicht gut.
outlierTest(model2)
#Wir haben wohl Ausrei�er!
plot(model2, which=4)
#Datensatz 42 ist ein Ausrei�er
plot(model2, which=5)
#Auch hier Datensatz 42

#------------ Model3 --------------#
summary(model3)
#model3 erkl�rt 37% der Varianz.
vif(model3)
#Alle Werte befinden sich unter 5 daher ist nur eine Geringe Abh�ngigkeit zu bemerken
par(mfrow=c(2,2))
plot(model3)
#Man k�nnte argumentieren das hier eine Bananenform erkennbar ist.
qqp(model3)
#Sieht gut aus.
crPlots(model3)
#pinke Linie weicht von blauer ab aber nicht so schlimm wie bei den anderen.
outlierTest(model3)
#Keine Ausrei�er
plot(model3, which=4)
#Alle Werte unter 0.5. Keine Ausrei�er erkennbar.
plot(model3, which=5)
#Auch keine Ausrei�er erkennbar.

#------------ Modelle vergleichen --------------#
anova(model1, model2, model3)
#model 3 hat den kleinsten RSS Wert. Ist demnach das beste Model von den Dreien.
AIC(model1, model2, model3)
#model3 hat auch den kleinsten AIC Wert. Ist demnach das beste Model von den Dreien.

#------------ Antwort Schritt 2 --------------#
#model3 sieht am besten aus bei den Modellvergleichen! Jedoch ist dieses Modell auch das
#einzige ohne Ausrei�er. Es w�re zu hinterfragen ob diese Ausrei�er Messfehler sind oder
#ob durch Domainenwissen gesagt werden kann das diese drinnen bleiben m�ssen!

# Schritt 3: Sie f�hren weitere Messungen zur Validierung durch (Datens�tze 176-215).
#            Welchen mittleren Fehler weisen die Modelle f�r diese Daten auf?
#            Mittlere Fehler = Wurzel(Mittelwert(Abweichung_von_Vorhersage^2))
#            Erkl�ren Sie in einem Satz, was der mittlere Fehler in der Praxis bedeutet.
#            Welches Messger�t w�rden Sie nun empfehlen?
dfn2 = df[176:215,]
mapply(hist, as.data.frame(dfn2), main = colnames(dfn2))
#Sieht viel Besser aus als die andere Messreihe.

#model1n = lm(fat ~ g1w1 + g1w2 + g1w3 + g1w4, data = dfn2)
#model2n = lm(fat ~ g2w1 + g2w2 + g2w3 + g2w4, data = dfn2)
#model3n = lm(fat ~ g3w1 + g3w2 + g3w3 + g3w4, data = dfn2)
#Brauchen wir wohl nicht. Neue Daten in altes Modell geben!

p1 = predict(model1, dfn2)
mf1 = sqrt(mean((dfn2$fat-p1)^2))
p2 = predict(model2, dfn2)
mf2 = sqrt(mean((dfn2$fat-p2)^2))
p3 = predict(model3, dfn2)
mf3 = sqrt(mean((dfn2$fat-p3)^2))

mf = c(mf1, mf2, mf3)
#11.95501
#12.80333
#10.37083
#model3 ist am besten.
#Je geringer die Abst�nde der Residuen zur Regressionsgerade ist umso besser.

# Schritt 4: Welche Kosten entstehen durch falsche/ungenaue Vorhersage des Fettanteils
#            im Schnitt pro Packung? Annahmen:
#            Falls |Abweichung|<10: 0€
#            Fleisch hat >+10 h�heren Fettanteil: 1.5€ pro Packung
#                                     (h�herer Verkaufswert h�tte erzielt werden k�nnen)
#            Fleisch hat <-10 kleineren Fettanteil: 3.7€ pro Packung
#                                     (Mittelwert der Kosten f�r Reklamationen)


k1 = ifelse(abs(dfn2$fat-p1) < 10, 0, ifelse((dfn2$fat-p1) > 10, 1.5, 3.7))
mean(k1) #0.75
k2 = ifelse(abs(dfn2$fat-p2) < 10, 0, ifelse((dfn2$fat-p2) > 10, 1.5, 3.7))
mean(k2) #0.7125
k3 = ifelse(abs(dfn2$fat-p3) < 10, 0, ifelse((dfn2$fat-p3) > 10, 1.5, 3.7))
mean(k3) #0.4125
#Es enstehen mit model3 nur 0.41cent Mehrkosten pro Packung.

# Schritt 5: Wir �berlegen, die beiden besseren Messger�te parallel einzusetzen.
#            Als Vorhersagewert wird dann einfach der Mittelwert der beiden Ger�te
#            verwendet. Anhand der Validierungsdaten aus Schritt 3: ist diese
#            Kombination besser oder schlechter als die einzelnen Messger�te?
#            Lohnt es sich, zwei unterschiedliche Messger�te anzuschaffen?
#            Wie gesichert sind Ihre Aussagen?
p4 = (p2+p3)/2
mf4 = sqrt(mean((dfn2$fat-p4)^2))

mf2 = c(mf1, mf2, mf3, mf4)
mf2
#11.95501
#12.80333
#10.37083
#11.13530
#model3 alleine ist besser.

# Allgemeine Tipps:
# - Lesen Sie die Angabe genau durch und setzen Sie die geforderten Punkte um.
#   Fleißaufgaben kosten Zeit, bringen aber keine zusätzlichen Punkte.
# - Die Interpretation (wo gefordert) muss so geschrieben sein, dass jede/jeder sie
#   verstehen kann (auch ohne mathematischen Hintergrund). Bedeutet unter anderem:
#   passend rücktransformieren falls transformiert wurde.
# - Die "ersten X Datensätze" meint wirklich *die ersten*. Keine Zufallsauswahl!
