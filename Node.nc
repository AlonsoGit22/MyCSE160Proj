/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"
//#define MAX_ROUTES 128
//#define MAX_TTL 120


typedef nx_struct RoutingTable {
nx_uint8_t rTable[19][3];
} RoutingTable;

module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;     // renames the nc file to sender 

   uses interface CommandHandler;
   uses interface List<uint16_t> as Neighbors;
   uses interface List<pack> as Packets;
   uses interface Timer<TMilli> as periodicTimer;
   uses interface Timer<TMilli> as DVRTimer;
}

implementation{
    pack sendPackage;
    uint16_t SENTINEL = 65535;
    uint16_t sequence = 0;
    uint8_t neighborDiscovered = 0;
    
    RoutingTable RoutingTables[20];
    
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
    void printTable() {
        uint16_t i,j,k;
        uint8_t currentRoute[19][3];
        
       for (k = 0; k < 19; k++) {
        memcpy(currentRoute, RoutingTables[TOS_NODE_ID].rTable, sizeof(currentRoute));
        dbg(ROUTING_CHANNEL, "Table for Node: %u \n", TOS_NODE_ID);
        printf("DEST    COST    HOP\n");
        for (i = 0; i < 19; i++){
            for (j = 0; j < 3; j++) {
                printf("%u; ", currentRoute[i][j]);
            }
            printf("\n");
        }
        }
    }
    
    void initTable() {
        uint16_t i, j, k, l, neighbor;
        uint8_t currentRoute[19][3];
       for (k = 0; k < 19; k++) {
        memcpy(currentRoute, RoutingTables[k].rTable, sizeof(currentRoute));
        for (i = 0; i < 19; i++) {
            currentRoute[i][0] = i+1;
            for (j = 1; j < 3; j++) {
                currentRoute[i][j] = SENTINEL;
            }
            //checks dest if itself, if it is, set cost to 0 and hop to itself.
            if (currentRoute[i][0] == TOS_NODE_ID) {
                currentRoute[i][1] = 0;
                currentRoute[i][2] = i+1;
            }
            //checks neighbors, sets cost to 1, hop to neighbor node
          /*  for (l = 0; l < 2; l++) {
             neighbor = call Neighbors.get(l);
             if (currentRoute.rTable[i][0] = neighbor) {
             currentRoute.rTable[i][1] = 1;
             currentRoute.rTable[i][2] = neighbor;
             }
             }
             */
        }
        
        memcpy(RoutingTables[TOS_NODE_ID].rTable, currentRoute, sizeof(currentRoute));
        }
        printTable();
    }
    
    void sendDVRTable() {                                                                    //sends current routing table to the neighbors
        
        //put a for loop in here to make sure it sends to all neighbors
        uint16_t i, j;
        uint8_t* payload;
        uint8_t currentRoute[19][3];
        for (j = 0; j < 19; j++) {
            memcpy(currentRoute, RoutingTables[j].rTable, sizeof(currentRoute));
            payload = (uint8_t*) currentRoute;
            
            for (i = 0; i < 2; i++) {
                makePack(&sendPackage, j+1, call Neighbors.get(i), 1, 5, sequence++, payload, PACKET_MAX_PAYLOAD_SIZE);
               // memcpy(&sendPackage->payload, call RoutingTables.get(i), sizeof(currentRoute));
                call Sender.send(sendPackage, AM_BROADCAST_ADDR);
            }
        }
        
    }
    
    void mergeRoute(pack *newPack) {                                            //not sure if argument is correct
        
        uint8_t i;
        uint8_t newRoute[19][3];
        uint8_t currentRoute[19][3];
        RoutingTable updatedTable;
        //newRoutes = newPack.payload;                                            //not sure if this syntax is correct
        
        initTable();
        
       // memcpy(currentRoute, newPack.payload, sizeof(newRoute));
       // memcpy(newRoute, RoutingTables[TOS_NODE_ID - 1].rTable, sizeof(currentRoute));
        for (i = 0; i < 19;  i++) {
            if (currentRoute[i][0] == newRoute[i][0]); {
                if (newRoute[i][1] + 1 < currentRoute[i][1]) {                    //shorter route found
                    currentRoute[i][1] = (newRoute[i][1] + 1);
                    currentRoute[i][2] = TOS_NODE_ID - 1;                            //hopefully this is correct lmfao
                }
            }
            
            //    if (currentRoute.rTable[i][1] == SENTINEL && newRoutes[i][1] != SENTINEL) {            //new route has been found
            //    currentRoute.rTable[i][1] = (newRoutes[i][1] + 1);
            //currentRoute.rTable[i][2] = newPack.src;
            //}
            
            if (currentRoute[i][0] == newRoute[i][0]); {
                if (newRoute[i][1] + 1 > currentRoute[i][1]) {                    //route is longer than the current route
                    break;
                }
            }
        }
        //updatedTable = currentRoute;
        memcpy(RoutingTables[TOS_NODE_ID].rTable, currentRoute, sizeof(currentRoute));
       // printTable();
    }

    
    

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   void discoverNeighbors(){
        //uint16_t tTol = 1;
        makePack(&sendPackage, TOS_NODE_ID, TOS_NODE_ID, 1, PROTOCOL_PING, sequence++, "HI NEIGHBOR", PACKET_MAX_PAYLOAD_SIZE);
        call Sender.send(sendPackage, AM_BROADCAST_ADDR);
        CommandHandler.printNeighbors;
   }
   event void periodicTimer.fired(){
       //ping(TOS_NODE_ID, "NEIGHBOR SEARCH");
        discoverNeighbors();
        //dbg(NEIGHBOR_CHANNEL,"Neighboring nodes %s\n", Neighbor);
        CommandHandler.printNeighbors;
        //dbg(NEIGHBOR_CHANNEL,"Neighboring nodes %s\n", Neighbor);
        
    }

   event void Boot.booted(){
      call AMControl.start();
      call periodicTimer.startPeriodic(5000);
       call DVRTimer.startPeriodic(6000);
      
      //dbg(GENERAL_CHANNEL, "Booted\n");
   }
    event void DVRTimer.fired() {
        sendDVRTable();
    }
    
   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         //dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   bool isDuplicate(uint16_t from, pack newPack){
       
       uint16_t i;
       uint16_t max = call Packets.size();
       for (i = 0; i < max;i++){
           pack oldPack = call Packets.get(i);
            if (oldPack.src == newPack.src && oldPack.seq == newPack.seq){
            //dbg(FLOODING_CHANNEL, "Packet is duplicate so its dropped\n");
            return TRUE;
            }
       }
    return FALSE;
   }

   

   event void AMControl.stopDone(error_t err){}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){   //name implies

        if(len==sizeof(pack)){
            pack* myMsg=(pack*) payload;
            // dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
            if (myMsg -> TTL == 0){
                //dbg(FLOODING_CHANNEL, "Packet Dropped due to TTL at 0\n");
                return msg;
            }
            else if (myMsg -> dest != TOS_NODE_ID){
                if (isDuplicate(myMsg -> src, *myMsg) == TRUE)
                    return msg;
                else if (myMsg -> src == myMsg -> dest){
                    int has = 0, i = 0;
                    for (i = 0; i < call Neighbors.size(); i++){
                        int temp = call Neighbors.get(i);
                        if (temp == myMsg -> src)
                            has++;
                    }
                    if (has == 0)
                        call Neighbors.pushback(myMsg -> src);
                    //CommandHandler.printNeighbors;
                    //dbg(NEIGHBOR_CHANNEL,"test\n");
                    //dbg(NEIGHBOR_CHANNEL, "we got a neighbor\n");
                }
                call Packets.pushback(*myMsg);
                
                myMsg -> TTL -= 1;                
                dbg(FLOODING_CHANNEL, "Packet Received from %d, flooding\n", myMsg->src);
                
                call Sender.send(*myMsg, AM_BROADCAST_ADDR);
            }
            //else if (myMsg -> dest == 0){
            //    call Neighbors.pushback(myMsg -> src);
            //    makePack(&sendPackage, TOS_NODE_ID, 0, MAX_TTL, PROTOCOL_PINGREPLY, sequence++, "Howdy Neighbor!", PACKET_MAX_PAYLOAD_SIZE);
                
            //    call Sender.send(sendPackage, AM_BROADCAST_ADDR);
            //}
        
            else if (myMsg -> protocol == PROTOCOL_PINGREPLY && myMsg -> dest == TOS_NODE_ID){
                dbg(GENERAL_CHANNEL, "Packet Recieved: %s\n", myMsg -> payload);
            }
            else { // myMsg -> dest == TOS_NODE_ID
                dbg(GENERAL_CHANNEL, "Packet Recieved: %s\n", myMsg -> payload);
                call Packets.pushback(*myMsg);
                makePack(&sendPackage, TOS_NODE_ID, myMsg -> src, MAX_TTL, PROTOCOL_PINGREPLY, sequence++, "Thank You.", PACKET_MAX_PAYLOAD_SIZE);
                call Sender.send(sendPackage, AM_BROADCAST_ADDR);
            }
            return msg;
        }
        dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
        return msg;
   }


   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n"); 
      makePack(&sendPackage, TOS_NODE_ID, destination, MAX_TTL, PROTOCOL_PING, sequence++, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Packets.pushback(sendPackage);
      call Sender.send(sendPackage, AM_BROADCAST_ADDR);
   }
   
   

   event void CommandHandler.printNeighbors(){
       
       uint16_t i = 0;
       uint16_t max = call Neighbors.size();   
       
       for(i = 0; i < max;i++){
           
          dbg(NEIGHBOR_CHANNEL,"i am printing\n");
         // uint16_t Neighbor = call Neighbors.get(i);
           //printf('%s', Neighbor);
          //dbg(NEIGHBOR_CHANNEL,"Neighboring nodes %s\n", Neighbor);

       }
   }

   event void CommandHandler.printRouteTable(){
       uint16_t i = 0;
       uint16_t j = 0;
       uint16_t max = 255;
       dbg(ROUTING_CHANNEL, "Routing Table \n");
       dbg(ROUTING_CHANNEL, "Dest   Hop    Count \n");
       dbg
       
     
        //dbg(ROUTING_CHANNEL, call routingTable.get(dest)," ", call routingTable.get(NextHop), "  ",call routingTable.get(cost));
   
   }
   
   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){
       int i;
       int max = call Neighbors.size();
       dbg(NEIGHBOR_CHANNEL, "I am node %u. my neighbors are:\n", TOS_NODE_ID);
       for(i = 0; i < max; i++){
           dbg(NEIGHBOR_CHANNEL, "%u\n", call Neighbors.get(i));
       }
   }

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
   
}
