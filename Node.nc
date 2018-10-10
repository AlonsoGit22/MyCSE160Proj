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
#define MAX_ROUTES 128
#define MAX_TTL 120

module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;     // renames the nc file to sender 

   uses interface CommandHandler;
   uses interface List<uint16_t> as Neighbors;
   uses interface List<pack> as Packets;
   uses interface Timer<TMilli> as periodicTimer;
}

implementation{
   pack sendPackage;
   uint16_t sequence = 0;

   // Prototypes
    struct routingTable {
        int dest;
        int NextHop;
        int cost;
        int src;
        unsigned short TTL;
    }Route;

int numRoutes = 0;
Route routingTable[MAX_Route];

    void mergeRoute (Route *new){//updates the local table of a node
        int i= src;
        for(i = 0; i < numRoutes; ++i){
            if(new -> dest == routingTable[i].dest){
                if( new -> cost + 1 < routingTable[i].cost){
                    break;
                }else if(new -> NextHop == routingTable[i].NextHop){ // possible change to the metric of the nextHop
                    break;
                }else{ // the route was not the best so just ignore it
                    return;
                }
            }
        }
        if( i == numRoutes){
            if( numRoutes < MAX_Route){
                ++numRoutes;
            }else{ // cant fit the route into the table
                return;
            }
        }
        routingTable[i] = *new;
        routingTable[i].TTL = MAX_TTL; // reset TTL because route was added
        ++routingTable[i].cost;
    }

    void updateRoutingTable (Route *newRoute, int numNewRoute){ //updates the table with the new routes from the node
        int i;
        for( i = 0; i < numRoutes; ++i){
            mergeRoute(&newRoute[i]);
        }
    }
    
struct fowardingTable {
    int dest;
int NextHop;
int cost
unsigned short TTL;
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

      
      //dbg(GENERAL_CHANNEL, "Booted\n");
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
           //uint16_t Neighbor = call Neighbors.get(i);
           //printf('%s', Neighbor);
           //dbg(NEIGHBOR_CHANNEL,"Neighboring nodes %s\n", Neighbor);

       }
   }

   event void CommandHandler.printRouteTable(){
       uint16_t i = 0;
       uint16_t max = call routingTable.size();
       
       for(i = 0; i < max; i++){
           dbg(ROUTING_CHANNEL, "hi");
       dbg(ROUTING_CHANNEL, "Routing Table \n");
        dbg(ROUTING_CHANNEL, "Dest   Hop    Count \n");
           dbg(ROUTING_CHANNEL, call routingTable.get(dest)," ", call routingTable.get(NextHop), "  ",call routingTable.get(cost));
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
