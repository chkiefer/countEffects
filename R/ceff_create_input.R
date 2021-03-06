ceff_create_input <- function(y,
                        x,
                        k,
                        z,
                        data,
                        measurement,
                        method,
                        distribution,
                        control
                        ){

  d <- data
  vnames <- list(y=y,x=x,k=k,z=z)

  if (distribution != "condNormal"){
    stop("CountEffects error: Distribution must be distribution = \"condNormal\".
         Other distributions are no longer supported.
         \nFor details see help(countEffects)")
  }

  if (!is.count(data[,y])){
    stop("CountEffects error: The dependent variable needs to consist of non-negative integers only.")
  }



  ## treatment variable as factor
  if(!is.factor(d[,x])){
    d[,x] <- as.factor(d[,x])
  }

  ## set control group level
  if(control=="default"){control <- levels(d[,x])[1]}
  d[,x] <- relevel(d[,x], control)
  levels.x.original <- levels(d[,x])
  levels(d[,x]) <- paste(0:(length(levels(d[,x]))-1))

  ## categorical covariates
  levels.k.original <- vector("list",length(k))
  names(levels.k.original) <- k

  if (!is.null(k)){
    for (i in 1:length(k)){
      d[,k[i]] <- as.factor(d[,k[i]])
      levels.k.original[[i]] <- levels(d[,k[i]])
      levels(d[,k[i]]) <- paste(0:(length(levels(d[,k[i]]))-1))
    }
  }

  ## unfolded k variable
  levels.kstar.original <- vector("character")
  if(!is.null(k)){
    if(length(k)>1){
      d$kstar <- apply(d[,k],1,paste,collapse="")
      d$kstar <- as.factor(d$kstar)
    }else{
      d$kstar <- d[,k]
    }
    levels.kstar.original <- levels(d$kstar)
    levels(d$kstar) <- paste(0:(length(levels(d$kstar))-1))

    ## check for empty cells
    if(any(table(d$kstar, d[,x]) == 0)){
      stop("EffectLiteR error: Empty cells are currently not allowed.")
    }
  } else {
    d$kstar <- NULL
  }

  ## nk
  nk <- 1L
  if(!is.null(k)){
    nk <- length(levels(d$kstar))
  }

  ## ng
  ng <- length(levels(d[,x]))

  ## nz
  nz <- length(vnames$z)

  ## longer parameter names for many groups and/or covariates
  sep <- ""
  if(ng>9 | nk>9 | nz>9){sep <- "_"}

  ## cell variable (xk-cells)
  if(!is.null(k)){
    dsub <- cbind(d[,x],d$kstar) - 1 # use x=0,1,2... and k=0,1,2,... as labels
    d$cell <- apply(dsub, 1, function(x){
      missing_ind <- sum(is.na(x)) > 0
      if(missing_ind){
        return(NA)
      }else{
        return(paste(x, collapse=sep))
      }
    })

    levels.cell <- expand.grid(k=levels(d$kstar), x=levels(d[,x]))
    levels.cell <- with(levels.cell, paste0(x,sep,k))
    d$cell <- factor(d$cell, levels=levels.cell)
  }else{
    d$cell <- d[,x]
  }
  ngroups <- length(levels(d$cell))


  ## add vlevels for created variables
  vlevels <- list(levels.x.original=levels.x.original,
                  levels.k.original=levels.k.original,
                  levels.kstar.original=levels.kstar.original,
                  x=levels(d[,x]),
                  kstar=levels(d$kstar),
                  cell=levels(d$cell))

  ## formula for CountReg
  if (nz){
    forml <- paste(y,"~",paste(z, collapse = "+"))
  } else {
    forml <- paste(y,"~ 1")
  }
  forml <- as.formula(forml)



  res <- new("input",
             method=method,
             vnames=vnames,
             vlevels=vlevels,
             ngroups=ngroups,
             control=control,
             ng=ng,
             nz=nz,
             nk=nk,
             data=d,
             measurement=measurement,
             distribution=distribution,
             forml=forml
  )

  return(res)
}
